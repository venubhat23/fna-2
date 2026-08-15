class Admin::PendingAmountsController < ApplicationController
  # See lib/local_ttl_cache.rb - Rails.cache is Solid Cache here (same remote Postgres
  # as the primary DB), so a Rails.cache "hit" still pays a network round trip. This
  # in-process cache turns the customer dropdown lookup below into a hash read.
  FILTER_LOCAL_CACHE = LocalTtlCache.new

  before_action :authenticate_user!
  before_action :set_pending_amount, only: [:update, :destroy]

  def index
    @pending_amounts = PendingAmount.includes(:customer)
                                   .order(created_at: :desc)
                                   .page(params[:page]).per(20)

    # Filter by month if specified
    if params[:month].present? && params[:year].present?
      start_date = Date.new(params[:year].to_i, params[:month].to_i, 1).beginning_of_month
      end_date = start_date.end_of_month
      @pending_amounts = @pending_amounts.where(pending_date: start_date..end_date)
    end

    # Cached: this dropdown's contents don't change per-request, but were reloaded
    # from the DB (as full AR objects) on every single index hit.
    @customers = FILTER_LOCAL_CACHE.fetch('admin_pending_amounts_customers', 10.minutes) do
      Customer.order(:first_name, :last_name).to_a
    end
    @new_pending_amount = PendingAmount.new
  end

  def create
    @pending_amount = PendingAmount.new(pending_amount_params)

    if @pending_amount.save
      render json: {
        success: true,
        message: 'Pending amount added successfully',
        pending_amount: {
          id: @pending_amount.id,
          customer_name: @pending_amount.customer.display_name,
          amount: @pending_amount.display_amount,
          description: @pending_amount.description,
          pending_date: @pending_amount.formatted_pending_date,
          status: @pending_amount.status.titleize,
          notes: @pending_amount.notes
        }
      }
    else
      render json: {
        success: false,
        message: 'Failed to add pending amount',
        errors: @pending_amount.errors.full_messages
      }
    end
  end

  def update
    if @pending_amount.update(pending_amount_params)
      render json: {
        success: true,
        message: 'Pending amount updated successfully',
        pending_amount: {
          id: @pending_amount.id,
          customer_name: @pending_amount.customer.display_name,
          amount: @pending_amount.display_amount,
          description: @pending_amount.description,
          pending_date: @pending_amount.formatted_pending_date,
          status: @pending_amount.status.titleize,
          notes: @pending_amount.notes
        }
      }
    else
      render json: {
        success: false,
        message: 'Failed to update pending amount',
        errors: @pending_amount.errors.full_messages
      }
    end
  end

  def destroy
    if @pending_amount.destroy
      render json: {
        success: true,
        message: 'Pending amount deleted successfully'
      }
    else
      render json: {
        success: false,
        message: 'Failed to delete pending amount'
      }
    end
  end

  private

  def set_pending_amount
    @pending_amount = PendingAmount.find(params[:id])
  end

  def pending_amount_params
    params.require(:pending_amount).permit(:customer_id, :amount, :description, :pending_date, :status, :notes)
  end
end
