class Customer::ClientRequestsController < Customer::ApplicationController
  before_action :authenticate_customer!

  def index
    # Loaded once; the view's stat cards and row loop all count in memory.
    @client_requests = current_customer.client_requests.order(created_at: :desc).to_a
  end

  def show
    @client_request = current_customer.client_requests.find(params[:id])
  end

  def new
    @client_request = current_customer.client_requests.build
  end

  def create
    @client_request = current_customer.client_requests.build(client_request_params)
    @client_request.status = 'pending'
    @client_request.priority = client_request_params[:priority] || 'medium'
    @client_request.stage = 'new'

    # Set customer information fields
    @client_request.name = current_customer.display_name || "#{current_customer.first_name} #{current_customer.last_name}".strip
    @client_request.email = current_customer.email
    @client_request.phone_number = current_customer.mobile

    if @client_request.save
      redirect_to customer_client_request_path(@client_request), notice: 'Your request has been submitted successfully. We will get back to you soon.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def client_request_params
    params.require(:client_request).permit(:title, :description, :priority, :department)
  end
end