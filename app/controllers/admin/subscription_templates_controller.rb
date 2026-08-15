class Admin::SubscriptionTemplatesController < Admin::ApplicationController
  before_action :set_subscription_template, only: [:show, :edit, :update, :destroy, :toggle_status, :apply_to_customer]

  def index
    @subscription_templates = SubscriptionTemplate.includes(:customer, :product, :delivery_person)
                                                  .order(created_at: :desc)
                                                  .page(params[:page])
  end

  def show
  end

  def new
    @subscription_template = SubscriptionTemplate.new
    load_form_dropdowns
  end

  def edit
    load_form_dropdowns
  end

  def create
    @subscription_template = SubscriptionTemplate.new(subscription_template_params)

    if @subscription_template.save
      redirect_to admin_subscription_templates_path, notice: 'Subscription template was successfully created.'
    else
      load_form_dropdowns
      render :new
    end
  end

  def update
    if @subscription_template.update(subscription_template_params)
      redirect_to admin_subscription_templates_path, notice: 'Subscription template was successfully updated.'
    else
      load_form_dropdowns
      render :edit
    end
  end

  def destroy
    @subscription_template.destroy
    redirect_to admin_subscription_templates_path, notice: 'Subscription template was successfully deleted.'
  end

  def toggle_status
    @subscription_template.update(is_active: !@subscription_template.is_active)
    redirect_to admin_subscription_templates_path, notice: 'Template status updated successfully.'
  end

  def apply_to_customer
    customer = Customer.find(params[:customer_id])

    # Create a new subscription based on the template
    subscription = MilkSubscription.new(
      customer: customer,
      product: @subscription_template.product,
      delivery_person: @subscription_template.delivery_person,
      quantity: @subscription_template.quantity,
      unit: @subscription_template.unit,
      price: @subscription_template.price,
      delivery_time: @subscription_template.delivery_time,
      start_date: Date.current,
      end_date: 1.month.from_now,
      is_active: true
    )

    if subscription.save
      redirect_to admin_subscription_path(subscription), notice: 'Subscription created from template successfully.'
    else
      redirect_back(fallback_location: admin_subscription_templates_path, alert: 'Failed to create subscription from template.')
    end
  end

  def active
    @subscription_templates = SubscriptionTemplate.where(is_active: true)
                                                  .includes(:customer, :product, :delivery_person)
                                                  .page(params[:page])
    render :index
  end

  private

  # Cached: these three form dropdowns don't change per-request, but were reloaded
  # from the DB (Customer.all as full AR objects, in particular) on every new/edit/
  # failed-save render.
  def load_form_dropdowns
    @customers = Rails.cache.fetch('admin_subscription_templates_customers', expires_in: 10.minutes) do
      Customer.all.to_a
    end
    @products = Rails.cache.fetch('admin_subscription_templates_products', expires_in: 10.minutes) do
      Product.where(product_type: 'milk').or(Product.where(is_subscription_enabled: true)).to_a
    end
    @delivery_people = Rails.cache.fetch('admin_subscription_templates_delivery_people', expires_in: 10.minutes) do
      DeliveryPerson.where(status: true).to_a
    end
  end

  def set_subscription_template
    @subscription_template = SubscriptionTemplate.find(params[:id])
  end

  def subscription_template_params
    params.require(:subscription_template).permit(:customer_id, :product_id, :delivery_person_id,
                                                  :quantity, :unit, :price, :delivery_time,
                                                  :is_active, :template_name, :notes)
  end
end