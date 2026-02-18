class Admin::SubscriptionsController < ApplicationController
  before_action :set_subscription, only: [:show, :edit, :update, :destroy, :toggle_status, :pause_subscription, :resume_subscription, :delivery_schedule, :generate_tasks]
  before_action :check_sidebar_permission

  def index
    @subscriptions = MilkSubscription.includes(:customer, :product)

    # Apply filters
    @subscriptions = filter_by_status(@subscriptions)
    @subscriptions = filter_by_date_range(@subscriptions)
    @subscriptions = filter_by_customer(@subscriptions)

    @subscriptions = @subscriptions.order(created_at: :desc).page(params[:page]).per(20)

    # For filter options
    @customers = Customer.all.pluck(:first_name, :last_name, :id).map { |f, l, id| ["#{f} #{l}".strip, id] }
    @products = Product.where(product_type: 'milk').pluck(:name, :id)

    # Summary statistics
    @stats = calculate_subscription_stats

    respond_to do |format|
      format.html
      format.json { render json: @subscriptions }
    end
  end

  def show
    @delivery_tasks = @subscription.milk_delivery_tasks.includes(:delivery_person).order(:delivery_date)
    @summary = @subscription.subscription_summary
  end

  def new
    @subscription = MilkSubscription.new
    @customers = Customer.all.map { |c| ["#{c.first_name} #{c.last_name} - #{c.mobile}", c.id] }
    # Show all active products or products suitable for subscriptions
    @products = Product.where(status: 'active').map { |p| [p.name, p.id] }
    @delivery_people = DeliveryPerson.where(status: true).map { |dp| ["#{dp.first_name} #{dp.last_name}", dp.id] }
  end

  def create
    @subscription = MilkSubscription.new(subscription_params)
    @subscription.created_by = current_user.id
    @subscription.total_amount = @subscription.calculate_total_amount

    if @subscription.save
      redirect_to admin_subscription_path(@subscription), notice: 'Subscription created successfully and all delivery tasks generated!'
    else
      @customers = Customer.all.map { |c| ["#{c.first_name} #{c.last_name} - #{c.mobile}", c.id] }
      @products = Product.where(status: 'active').map { |p| [p.name, p.id] }
      @delivery_people = DeliveryPerson.where(status: true).map { |dp| ["#{dp.first_name} #{dp.last_name}", dp.id] }
      render :new
    end
  end

  def edit
    @customers = Customer.all.map { |c| ["#{c.first_name} #{c.last_name} - #{c.mobile}", c.id] }
    @products = Product.where(status: 'active').map { |p| [p.name, p.id] }
    @delivery_people = DeliveryPerson.where(status: true).map { |dp| ["#{dp.first_name} #{dp.last_name}", dp.id] }
  end

  def update
    if @subscription.update(subscription_params)
      redirect_to admin_subscription_path(@subscription), notice: 'Subscription updated successfully!'
    else
      @customers = Customer.all.map { |c| ["#{c.first_name} #{c.last_name} - #{c.mobile}", c.id] }
      @products = Product.where(status: 'active').map { |p| [p.name, p.id] }
      @delivery_people = DeliveryPerson.where(status: true).map { |dp| ["#{dp.first_name} #{dp.last_name}", dp.id] }
      render :edit
    end
  end

  def destroy
    @subscription.destroy
    redirect_to admin_subscriptions_path, notice: 'Subscription deleted successfully!'
  end

  def toggle_status
    new_status = @subscription.is_active? ? false : true
    @subscription.update(is_active: new_status)
    status_text = new_status ? 'activated' : 'deactivated'
    redirect_to admin_subscriptions_path, notice: "Subscription #{status_text} successfully!"
  end

  def pause_subscription
    @subscription.update(status: 'paused')
    redirect_to admin_subscription_path(@subscription), notice: 'Subscription paused successfully!'
  end

  def resume_subscription
    @subscription.update(status: 'active')
    redirect_to admin_subscription_path(@subscription), notice: 'Subscription resumed successfully!'
  end

  def delivery_schedule
    @delivery_tasks = @subscription.milk_delivery_tasks.includes(:delivery_person).order(:delivery_date)
    render json: @delivery_tasks.as_json(include: { delivery_person: { only: [:first_name, :last_name] } })
  end

  def generate_tasks
    # Regenerate tasks (useful if subscription was modified)
    @subscription.milk_delivery_tasks.destroy_all
    @subscription.generate_all_delivery_tasks
    redirect_to admin_subscription_path(@subscription), notice: 'Delivery tasks regenerated successfully!'
  end

  # Filter actions
  def active
    redirect_to admin_subscriptions_path(status: 'active')
  end

  def paused
    redirect_to admin_subscriptions_path(status: 'paused')
  end

  def expired
    redirect_to admin_subscriptions_path(status: 'expired')
  end

  private

  def set_subscription
    @subscription = MilkSubscription.find(params[:id])
  end

  def subscription_params
    params.require(:milk_subscription).permit(
      :customer_id, :product_id, :quantity, :unit, :start_date, :end_date,
      :delivery_time, :delivery_pattern, :specific_dates, :status, :is_active
    )
  end

  def filter_by_status(subscriptions)
    if params[:status].present?
      subscriptions.where(status: params[:status])
    else
      subscriptions
    end
  end

  def filter_by_date_range(subscriptions)
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      subscriptions.for_date_range(start_date, end_date)
    else
      subscriptions
    end
  end

  def filter_by_customer(subscriptions)
    if params[:customer_id].present?
      subscriptions.where(customer_id: params[:customer_id])
    else
      subscriptions
    end
  end

  def calculate_subscription_stats
    total = MilkSubscription.count
    active = MilkSubscription.where(status: 'active').count
    paused = MilkSubscription.where(status: 'paused').count
    expired = MilkSubscription.where(status: 'expired').count

    today_deliveries = MilkDeliveryTask.for_today.count
    pending_today = MilkDeliveryTask.for_today.pending.count

    {
      total: total,
      active: active,
      paused: paused,
      expired: expired,
      today_deliveries: today_deliveries,
      pending_today: pending_today
    }
  end

  def check_sidebar_permission
    unless current_user.has_sidebar_permission?('subscriptions')
      redirect_to admin_dashboard_path, alert: 'You do not have permission to access this page.'
    end
  end
end