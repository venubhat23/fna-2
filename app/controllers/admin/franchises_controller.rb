class Admin::FranchisesController < Admin::ApplicationController
  include LocationData
  include ConfigurablePagination
  before_action :set_franchise, only: [:show, :edit, :update, :destroy, :toggle_status]

  # GET /admin/franchises
  def index
    # Check if search is active first
    search_active = params[:search].present? && params[:search].strip.length >= 4

    if search_active
      # When search is active, use simpler query without select optimization
      @franchises = Franchise.all
    else
      # Use standard query
      @franchises = Franchise.all
    end

    # Search functionality - only search if 4+ characters or empty
    if params[:search].present?
      search_term = params[:search].strip
      if search_term.length >= 4
        @franchises = @franchises.search_franchises(search_term)
      elsif search_term.length > 0
        # Return empty result if search term is too short
        @franchises = @franchises.none
      end
    end

    # Filter by status
    case params[:status]
    when 'active'
      @franchises = @franchises.where(status: true)
    when 'inactive'
      @franchises = @franchises.where(status: false)
    end

    # Get total count before pagination for display purposes
    @total_filtered_count = @franchises.count

    # Order and paginate using configurable pagination
    @franchises = paginate_records(@franchises.order(created_at: :desc))

    # Calculate statistics
    stats_scope = Franchise.all

    # Apply filters but handle search differently for stats
    if params[:search].present? && params[:search].strip.length >= 4
      search_term = params[:search].strip
      stats_scope = stats_scope.where(
        "name ILIKE ? OR email ILIKE ? OR mobile ILIKE ? OR contact_person_name ILIKE ? OR city ILIKE ?",
        "%#{search_term}%", "%#{search_term}%", "%#{search_term}%", "%#{search_term}%", "%#{search_term}%"
      )
    end

    case params[:status]
    when 'active'
      stats_scope = stats_scope.where(status: true)
    when 'inactive'
      stats_scope = stats_scope.where(status: false)
    end

    # Calculate filtered stats
    @stats = {
      total_franchises: stats_scope.count,
      active_franchises: stats_scope.where(status: true).count,
      inactive_franchises: stats_scope.where(status: false).count,
      total_commission: stats_scope.sum(:commission_percentage) || 0,
      avg_commission: stats_scope.average(:commission_percentage) || 0
    }

    @total_franchises = @stats[:total_franchises]
    @active_franchises = @stats[:active_franchises]
    @inactive_franchises = @stats[:inactive_franchises]

    # Handle AJAX requests
    respond_to do |format|
      format.html # Regular HTML request
      format.json { render json: { franchises: @franchises, stats: @stats } }
    end
  end

  # GET /admin/franchises/1
  def show
    # Additional data for show page can be added here
  end

  # GET /admin/franchises/new
  def new
    @franchise = Franchise.new
    @franchise.status = true
  end

  # GET /admin/franchises/1/edit
  def edit
  end

  # POST /admin/franchises
  def create
    # Extract password params separately before creating franchise
    password = params[:franchise][:password]
    password_confirmation = params[:franchise][:password_confirmation]
    auto_generate_password = params[:franchise][:auto_generate_password]

    @franchise = Franchise.new(franchise_params)

    begin
      ActiveRecord::Base.transaction do
        # Handle password generation
        if auto_generate_password == '1' || password.blank?
          # Auto-generate password
          generated_password = generate_secure_password
          @franchise.password = generated_password
          @franchise.password_confirmation = generated_password
        else
          # Use provided password
          @franchise.password = password
          @franchise.password_confirmation = password_confirmation
        end

        if @franchise.save
          if auto_generate_password == '1' || password.blank?
            flash[:generated_password] = @franchise.auto_generated_password
            redirect_to admin_franchise_path(@franchise),
                       notice: "Franchise created successfully. Auto-generated password: #{@franchise.auto_generated_password}"
          else
            redirect_to admin_franchise_path(@franchise), notice: 'Franchise was successfully created.'
          end
        else
          render :new, status: :unprocessable_entity
        end
      end
    rescue => e
      @franchise.errors.add(:base, "Failed to create franchise: #{e.message}")
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /admin/franchises/1
  def update
    if @franchise.update(franchise_params)
      redirect_to admin_franchise_path(@franchise), notice: 'Franchise was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/franchises/1
  def destroy
    @franchise.destroy
    redirect_to admin_franchises_path, notice: 'Franchise was successfully deleted.'
  end

  # PATCH /admin/franchises/1/toggle_status
  def toggle_status
    @franchise.update(status: !@franchise.status)
    status_text = @franchise.status? ? 'activated' : 'deactivated'
    redirect_to admin_franchises_path, notice: "Franchise was successfully #{status_text}."
  end

  # GET /admin/franchises/export
  def export
    @franchises = Franchise.all

    # Apply same filters as index
    if params[:search].present?
      @franchises = @franchises.search_franchises(params[:search])
    end

    case params[:status]
    when 'active'
      @franchises = @franchises.active
    when 'inactive'
      @franchises = @franchises.inactive
    end

    @franchises = @franchises.order(:created_at)

    respond_to do |format|
      format.csv do
        send_data generate_franchises_csv(@franchises), filename: "franchises_#{Date.current}.csv"
      end
    end
  end

  private

  # Generate a secure password for auto-creation
  def generate_secure_password
    # Generate password in format: first 4 letters of name + @ + 4-digit year
    # Example: FRANCHISE with establishment date 2023 becomes FRAN@2023

    # Get franchise name
    name = @franchise.name.to_s.strip.upcase

    # Get first 4 characters of name, pad with 'X' if less than 4 characters
    name_part = name[0..3].ljust(4, 'X')

    # Get establishment year or current year
    if @franchise.establishment_date.present?
      year_part = @franchise.establishment_date.year.to_s
    else
      # Default to current year if no establishment date
      year_part = Date.current.year.to_s
    end

    "#{name_part}@#{year_part}"
  end

  def set_franchise
    @franchise = Franchise.find(params[:id])
  end

  def franchise_params
    params.require(:franchise).permit(
      :name, :email, :mobile, :contact_person_name, :business_type, :address, :city, :state, :pincode,
      :pan_no, :gst_no, :license_no, :establishment_date, :territory, :franchise_fee, :commission_percentage,
      :status, :notes, :longitude, :latitude, :whatsapp_number, :profile_image, :business_documents
    )
  end

  def generate_franchises_csv(franchises)
    require 'csv'

    CSV.generate(headers: true) do |csv|
      csv << %w[
        ID Name Email Mobile ContactPerson BusinessType Address City State Pincode
        PANNumber GSTNumber LicenseNumber EstablishmentDate Territory FranchiseFee
        CommissionPercentage Status Notes CreatedAt
      ]

      franchises.find_each do |franchise|
        csv << [
          franchise.id,
          franchise.name,
          franchise.email,
          franchise.mobile,
          franchise.contact_person_name,
          franchise.business_type,
          franchise.address,
          franchise.city,
          franchise.state,
          franchise.pincode,
          franchise.pan_no,
          franchise.gst_no,
          franchise.license_no,
          franchise.establishment_date,
          franchise.territory,
          franchise.franchise_fee,
          franchise.commission_percentage,
          franchise.status? ? 'Active' : 'Inactive',
          franchise.notes,
          franchise.created_at.strftime('%Y-%m-%d %H:%M:%S')
        ]
      end
    end
  end
end
