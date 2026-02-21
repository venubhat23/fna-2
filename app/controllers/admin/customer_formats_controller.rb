class Admin::CustomerFormatsController < Admin::ApplicationController
  before_action :set_customer_format, only: [:show, :edit, :update, :destroy, :toggle_status]
  before_action :check_sidebar_permission
  skip_before_action :check_sidebar_permission, only: [:import_from_master]

  def index
    @customer_formats = CustomerFormat.includes(:customer, :product, :delivery_person)

    # Apply filters
    @customer_formats = filter_by_status(@customer_formats)
    @customer_formats = filter_by_customer(@customer_formats)
    @customer_formats = filter_by_pattern(@customer_formats)

    @customer_formats = @customer_formats.order(created_at: :desc).page(params[:page]).per(20)

    # For filter options
    @customers = Customer.all.pluck(:first_name, :last_name, :id).map { |f, l, id| ["#{f} #{l}".strip, id] }
    @products = Product.where(status: 'active').pluck(:name, :id)
    @delivery_people = DeliveryPerson.where(status: true).pluck(:first_name, :last_name, :id).map { |f, l, id| ["#{f} #{l}".strip, id] }

    # Summary statistics
    @stats = calculate_customer_format_stats

    respond_to do |format|
      format.html
      format.json { render json: @customer_formats }
    end
  end

  def show
  end

  def new
    @customer_format = CustomerFormat.new
    load_form_data
  end

  def create
    @customer_format = CustomerFormat.new(customer_format_params)

    if @customer_format.save
      redirect_to admin_customer_format_path(@customer_format), notice: 'Customer format created successfully!'
    else
      load_form_data
      render :new
    end
  end

  def edit
    load_form_data
  end

  def update
    if @customer_format.update(customer_format_params)
      redirect_to admin_customer_format_path(@customer_format), notice: 'Customer format updated successfully!'
    else
      load_form_data
      render :edit
    end
  end

  def destroy
    @customer_format.destroy
    redirect_to admin_customer_formats_path, notice: 'Customer format deleted successfully!'
  end

  def toggle_status
    new_status = @customer_format.status == 'active' ? 'not_active' : 'active'
    @customer_format.update(status: new_status)
    status_text = new_status == 'active' ? 'activated' : 'deactivated'
    redirect_to admin_customer_formats_path, notice: "Customer format #{status_text} successfully!"
  end

  # Search helpers for AJAX calls
  def search_customers
    term = params[:q]
    customers = Customer.where("CONCAT(first_name, ' ', last_name) ILIKE ?", "%#{term}%")
                       .limit(20)
                       .pluck(:first_name, :last_name, :id)
                       .map { |f, l, id| { id: id, text: "#{f} #{l}".strip } }
    render json: { results: customers }
  end

  def search_products
    term = params[:q]
    products = Product.where(status: 'active')
                     .where("name ILIKE ?", "%#{term}%")
                     .limit(20)
                     .pluck(:name, :id)
                     .map { |name, id| { id: id, text: name } }
    render json: { results: products }
  end

  def search_delivery_people
    term = params[:q]
    delivery_people = DeliveryPerson.where(status: true)
                                   .where("CONCAT(first_name, ' ', last_name) ILIKE ?", "%#{term}%")
                                   .limit(20)
                                   .pluck(:first_name, :last_name, :id)
                                   .map { |f, l, id| { id: id, text: "#{f} #{l}".strip } }
    render json: { results: delivery_people }
  end

  # Import page action
  def import_page
    # Summary statistics for the import page
    @stats = calculate_customer_format_stats

    # Get detailed format information
    @active_formats = CustomerFormat.includes(:customer, :product, :delivery_person).where(status: 'active').limit(50)

    respond_to do |format|
      format.html
    end
  end

  # Import from Master Subscription action
  def import_from_master
    month = params[:month].to_i
    year = params[:year].to_i

    # Validate parameters
    if month < 1 || month > 12 || year < Date.current.year || year > Date.current.year + 5
      respond_to do |format|
        format.json { render json: { success: false, message: 'Invalid month or year selected.' }, status: :bad_request }
      end
      return
    end

    begin
      # Queue the background job
      ImportMasterSubscriptionJob.perform_later(month, year)

      message = "Copy process started successfully. Please wait 10 minutes. Subscriptions are being created in the background."

      respond_to do |format|
        format.json { render json: { success: true, message: message } }
      end
    rescue => e
      Rails.logger.error "Error starting import job: #{e.message}"

      respond_to do |format|
        format.json { render json: { success: false, message: 'Failed to start import process. Please try again.' }, status: :internal_server_error }
      end
    end
  end

  private

  def set_customer_format
    @customer_format = CustomerFormat.find_by(id: params[:id])
    unless @customer_format
      redirect_to admin_customer_formats_path, alert: 'Customer format not found.'
    end
  end

  def customer_format_params
    params.require(:customer_format).permit(:customer_id, :pattern, :quantity, :product_id, :delivery_person_id, :status, days: [])
  end

  def load_form_data
    @customers = Customer.all.map { |c| ["#{c.first_name} #{c.last_name} - #{c.mobile}", c.id] }
    @products = Product.where(status: 'active').map { |p| [p.name, p.id] }
    @delivery_people = DeliveryPerson.where(status: true).map { |dp| ["#{dp.first_name} #{dp.last_name}", dp.id] }
    @pattern_options = CustomerFormat::PATTERN_OPTIONS.map { |pattern| [pattern.humanize, pattern] }
    @status_options = CustomerFormat::STATUS_OPTIONS.map { |status| [status.humanize, status] }
  end

  def filter_by_status(customer_formats)
    if params[:status].present?
      customer_formats.where(status: params[:status])
    else
      customer_formats
    end
  end

  def filter_by_customer(customer_formats)
    if params[:customer_id].present?
      customer_formats.where(customer_id: params[:customer_id])
    else
      customer_formats
    end
  end

  def filter_by_pattern(customer_formats)
    if params[:pattern].present?
      customer_formats.where(pattern: params[:pattern])
    else
      customer_formats
    end
  end

  def calculate_customer_format_stats
    total = CustomerFormat.count
    active = CustomerFormat.where(status: 'active').count
    inactive = CustomerFormat.where(status: 'not_active').count

    pattern_counts = CustomerFormat.group(:pattern).count

    {
      total: total,
      active: active,
      inactive: inactive,
      pattern_counts: pattern_counts
    }
  end

  def check_sidebar_permission
    unless current_user && current_user.has_sidebar_permission?('customer_formats')
      redirect_to admin_dashboard_path, alert: 'You do not have permission to access this page.'
    end
  end
end
