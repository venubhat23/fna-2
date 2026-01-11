class Api::V1::ClientRequestsController < ApplicationController
  before_action :authenticate_user!, except: [:create]
  before_action :set_client_request, only: [:show, :update, :destroy, :transition_stage, :assign_to_user, :update_priority, :stage_history]

  # GET /api/v1/client_requests
  def index
    @client_requests = ClientRequest.includes(:assignee, :resolved_by)

    # Apply filters
    @client_requests = @client_requests.by_stage(params[:stage]) if params[:stage].present?
    @client_requests = @client_requests.by_department(params[:department]) if params[:department].present?
    @client_requests = @client_requests.by_priority(params[:priority]) if params[:priority].present?
    @client_requests = @client_requests.assigned_to(params[:assignee_id]) if params[:assignee_id].present?

    # Search
    if params[:search].present?
      @client_requests = @client_requests.search_requests(params[:search])
    end

    # Pagination
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 25
    @client_requests = @client_requests.offset((page - 1) * per_page).limit(per_page)

    render json: {
      success: true,
      data: @client_requests.map { |request| format_client_request(request) },
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: ClientRequest.count
      }
    }
  end

  # GET /api/v1/client_requests/:id
  def show
    render json: {
      success: true,
      data: format_client_request_details(@client_request)
    }
  end

  # POST /api/v1/client_requests
  def create
    @client_request = ClientRequest.new(client_request_params)

    if @client_request.save
      render json: {
        success: true,
        message: 'Client request submitted successfully',
        data: format_client_request(@client_request)
      }, status: :created
    else
      render json: {
        success: false,
        errors: @client_request.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/client_requests/:id
  def update
    if @client_request.update(client_request_update_params)
      render json: {
        success: true,
        message: 'Client request updated successfully',
        data: format_client_request(@client_request)
      }
    else
      render json: {
        success: false,
        errors: @client_request.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/client_requests/:id/transition_stage
  def transition_stage
    new_stage = params[:stage]
    notes = params[:notes]

    if @client_request.can_transition_to?(new_stage)
      begin
        @client_request.transition_to_stage!(new_stage, user: current_user, notes: notes)
        render json: {
          success: true,
          message: "Request transitioned to #{new_stage.humanize}",
          data: format_client_request(@client_request)
        }
      rescue => e
        render json: {
          success: false,
          error: "Failed to transition stage: #{e.message}"
        }, status: :unprocessable_entity
      end
    else
      render json: {
        success: false,
        error: "Invalid stage transition from #{@client_request.stage} to #{new_stage}"
      }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/client_requests/:id/assign_to_user
  def assign_to_user
    user = User.find_by(id: params[:user_id])

    if user
      @client_request.update!(
        assignee: user,
        stage: 'assigned',
        stage_updated_at: Time.current
      )
      render json: {
        success: true,
        message: "Request assigned to #{user.first_name} #{user.last_name}",
        data: format_client_request(@client_request)
      }
    else
      render json: {
        success: false,
        error: 'User not found'
      }, status: :not_found
    end
  end

  # PATCH /api/v1/client_requests/:id/update_priority
  def update_priority
    new_priority = params[:priority]

    if ClientRequest::PRIORITIES.include?(new_priority)
      @client_request.update!(priority: new_priority)
      render json: {
        success: true,
        message: "Priority updated to #{new_priority.humanize}",
        data: format_client_request(@client_request)
      }
    else
      render json: {
        success: false,
        error: 'Invalid priority level'
      }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/client_requests/:id/stage_history
  def stage_history
    history = @client_request.stage_history.present? ? JSON.parse(@client_request.stage_history) : []

    render json: {
      success: true,
      data: {
        ticket_number: @client_request.ticket_number,
        current_stage: @client_request.stage,
        history: history.map { |entry|
          entry.merge(
            'changed_by_name' => entry['changed_by'] ? User.find_by(id: entry['changed_by'])&.first_name : nil
          )
        }
      }
    }
  end

  # Collection actions for filtering and statistics

  # GET /api/v1/client_requests/by_stage
  def by_stage
    stage = params[:stage]
    requests = ClientRequest.by_stage(stage).includes(:assignee, :resolved_by)

    render json: {
      success: true,
      stage: stage,
      count: requests.count,
      data: requests.map { |request| format_client_request(request) }
    }
  end

  # GET /api/v1/client_requests/by_department
  def by_department
    department = params[:department]
    requests = ClientRequest.by_department(department).includes(:assignee, :resolved_by)

    render json: {
      success: true,
      department: department,
      count: requests.count,
      data: requests.map { |request| format_client_request(request) }
    }
  end

  # GET /api/v1/client_requests/overdue
  def overdue
    requests = ClientRequest.overdue.includes(:assignee, :resolved_by)

    render json: {
      success: true,
      count: requests.count,
      data: requests.map { |request| format_client_request(request).merge(
        hours_overdue: request.estimated_hours_remaining * -1
      )}
    }
  end

  # GET /api/v1/client_requests/unassigned
  def unassigned
    requests = ClientRequest.unassigned.where.not(stage: ['closed', 'resolved'])

    render json: {
      success: true,
      count: requests.count,
      data: requests.map { |request| format_client_request(request) }
    }
  end

  # GET /api/v1/client_requests/stage_statistics
  def stage_statistics
    stats = {}

    ClientRequest::STAGES.each do |stage|
      stats[stage] = ClientRequest.by_stage(stage).count
    end

    priority_stats = {}
    ClientRequest::PRIORITIES.each do |priority|
      priority_stats[priority] = ClientRequest.by_priority(priority).count
    end

    render json: {
      success: true,
      data: {
        stage_counts: stats,
        priority_counts: priority_stats,
        total_requests: ClientRequest.count,
        overdue_count: ClientRequest.overdue.count,
        unassigned_count: ClientRequest.unassigned.count,
        average_resolution_time_hours: calculate_average_resolution_time
      }
    }
  end

  private

  def set_client_request
    @client_request = ClientRequest.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      error: 'Client request not found'
    }, status: :not_found
  end

  def client_request_params
    params.require(:client_request).permit(
      :name, :email, :phone_number, :description, :priority, :department
    )
  end

  def client_request_update_params
    params.require(:client_request).permit(
      :description, :priority, :department, :admin_response,
      :estimated_resolution_time
    )
  end

  def format_client_request(request)
    {
      id: request.id,
      ticket_number: request.ticket_number,
      name: request.name,
      email: request.email,
      phone_number: request.phone_number,
      description: request.description.truncate(100),
      status: request.status,
      stage: request.stage,
      priority: request.priority,
      department: request.department,
      submitted_at: request.submitted_at,
      stage_updated_at: request.stage_updated_at,
      days_since_submission: request.days_since_submission,
      stage_duration_hours: request.stage_duration.round(1),
      assignee: request.assignee ? {
        id: request.assignee.id,
        name: "#{request.assignee.first_name} #{request.assignee.last_name}",
        email: request.assignee.email
      } : nil,
      is_overdue: request.is_overdue?,
      estimated_hours_remaining: request.estimated_hours_remaining
    }
  end

  def format_client_request_details(request)
    format_client_request(request).merge(
      full_description: request.description,
      admin_response: request.admin_response,
      resolved_at: request.resolved_at,
      estimated_resolution_time: request.estimated_resolution_time,
      actual_resolution_time: request.actual_resolution_time,
      resolved_by: request.resolved_by ? {
        id: request.resolved_by.id,
        name: "#{request.resolved_by.first_name} #{request.resolved_by.last_name}"
      } : nil,
      possible_transitions: request.stage ?
        ClientRequest::STAGES.select { |stage| request.can_transition_to?(stage) } : []
    )
  end

  def calculate_average_resolution_time
    resolved_requests = ClientRequest.where.not(actual_resolution_time: nil, submitted_at: nil)
    return 0 if resolved_requests.empty?

    total_hours = resolved_requests.sum do |request|
      (request.actual_resolution_time - request.submitted_at) / 1.hour
    end

    (total_hours / resolved_requests.count).round(1)
  end
end