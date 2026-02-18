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
    @customers = Customer.all
    @products = Product.where(product_type: 'milk').or(Product.where(is_subscription_enabled: true))
    @delivery_people = DeliveryPerson.where(status: true)
  end

  def edit
    @customers = Customer.all
    @products = Product.where(product_type: 'milk').or(Product.where(is_subscription_enabled: true))
    @delivery_people = DeliveryPerson.where(status: true)
  end

  def create
    @subscription_template = SubscriptionTemplate.new(subscription_template_params)

    if @subscription_template.save
      redirect_to admin_subscription_templates_path, notice: 'Subscription template was successfully created.'
    else
      @customers = Customer.all
      @products = Product.where(product_type: 'milk').or(Product.where(is_subscription_enabled: true))
      @delivery_people = DeliveryPerson.where(status: true)
      render :new
    end
  end

  def update
    if @subscription_template.update(subscription_template_params)
      redirect_to admin_subscription_templates_path, notice: 'Subscription template was successfully updated.'
    else
      @customers = Customer.all
      @products = Product.where(product_type: 'milk').or(Product.where(is_subscription_enabled: true))
      @delivery_people = DeliveryPerson.where(status: true)
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

  def set_subscription_template
    @subscription_template = SubscriptionTemplate.find(params[:id])
  end

  def subscription_template_params
    params.require(:subscription_template).permit(:customer_id, :product_id, :delivery_person_id,
                                                  :quantity, :unit, :price, :delivery_time,
                                                  :is_active, :template_name, :notes)
  end
end