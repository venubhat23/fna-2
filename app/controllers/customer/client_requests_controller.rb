class Customer::ClientRequestsController < Customer::ApplicationController
  before_action :authenticate_customer!

  def index
    @client_requests = current_customer.client_requests.order(created_at: :desc)
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
    @client_request.priority = 'medium'
    @client_request.stage = 'new'

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