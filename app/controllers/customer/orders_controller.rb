class Customer::OrdersController < Customer::BaseController
  before_action :find_order, only: [:show, :track, :invoice]

  def index
    @orders = current_customer.orders
                             .includes(:booking)
                             .order(created_at: :desc)
                             .page(params[:page]).per(10)

    # Filter by status if provided
    if params[:status].present?
      @orders = @orders.where(status: params[:status])
    end
  end

  def show
    @order_items = JSON.parse(@order.order_items || '[]')
  end

  def track
    @tracking_info = {
      order_number: @order.order_number,
      status: @order.status,
      order_date: @order.order_date,
      estimated_delivery: @order.order_date + 7.days,
      tracking_number: @order.tracking_number
    }
  end

  def invoice
    # This would generate and download an invoice
    respond_to do |format|
      format.pdf do
        render pdf: "invoice_#{@order.order_number}",
               template: 'customer/orders/invoice.pdf.erb',
               layout: 'pdf'
      end
      format.html { redirect_to customer_order_path(@order) }
    end
  end

  private

  def find_order
    @order = current_customer.orders.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to customer_orders_path, alert: 'Order not found.'
  end
end