class Customer::ApplicationController < ApplicationController
  before_action :authenticate_customer_user!
  before_action :set_current_customer
  layout 'customer'

  private

  def authenticate_customer_user!
    # Check if user is logged in and is a customer
    unless user_signed_in? && current_user&.customer?
      redirect_to new_user_session_path, alert: 'Please log in as a customer to access this page.'
    end
  end

  def set_current_customer
    if current_user&.customer?
      @current_customer = Customer.find_by(email: current_user.email)
      unless @current_customer
        redirect_to new_user_session_path, alert: 'Customer account not found. Please contact support.'
      end
    end
  end

  def current_customer
    @current_customer
  end
  helper_method :current_customer
end