class Customer::SubscriptionsController < Customer::BaseController
  before_action :find_subscription, only: [:show, :edit, :update, :pause, :resume, :cancel, :destroy]

  def index
    @active_subscriptions = current_customer.milk_subscriptions.where(is_active: true)
    @paused_subscriptions = current_customer.milk_subscriptions.where(is_active: false)
  end

  def show
    @upcoming_deliveries = 7 # This would be calculated based on subscription
  end

  def new
    @subscription = current_customer.milk_subscriptions.build
    @products = Product.active.subscription_enabled

    # If product_id is provided in params, pre-select it
    if params[:product_id].present?
      @subscription.product_id = params[:product_id]
    end
  end

  def create
    @subscription = current_customer.milk_subscriptions.build(subscription_params)

    if @subscription.save
      redirect_to customer_subscription_path(@subscription), notice: 'Subscription created successfully!'
    else
      @products = Product.active.subscription_enabled
      render :new
    end
  end

  def edit
    @products = Product.active.subscription_enabled
  end

  def update
    if @subscription.update(subscription_params)
      redirect_to customer_subscription_path(@subscription), notice: 'Subscription updated successfully!'
    else
      @products = Product.active.subscription_enabled
      render :edit
    end
  end

  def pause
    @subscription.update(is_active: false)
    redirect_to customer_subscription_path(@subscription), notice: 'Subscription paused successfully!'
  end

  def resume
    @subscription.update(is_active: true)
    redirect_to customer_subscription_path(@subscription), notice: 'Subscription resumed successfully!'
  end

  def cancel
    @subscription.destroy
    redirect_to customer_subscriptions_path, notice: 'Subscription cancelled successfully!'
  end

  private

  def find_subscription
    @subscription = current_customer.milk_subscriptions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to customer_subscriptions_path, alert: 'Subscription not found.'
  end

  def subscription_params
    params.require(:milk_subscription).permit(
      :product_id, :quantity, :unit, :start_date, :end_date,
      :delivery_time, :is_active
    )
  end
end