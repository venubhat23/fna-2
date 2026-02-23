class Customer::BaseController < ApplicationController
  # Skip Devise authentication and CanCan authorization for customer controllers
  skip_before_action :authenticate_user!
  skip_load_and_authorize_resource

  before_action :authenticate_customer!
  before_action :ensure_customer_role
  layout 'customer'

  protected

  def authenticate_customer!
    # Check if this is a login/register page - don't authenticate
    return if action_name == 'new' || action_name == 'create'

    unless customer_signed_in?
      redirect_to customer_login_path, alert: 'Please log in to access this page.'
    end
  end

  def customer_signed_in?
    session[:customer_id].present? && current_customer.present?
  end

  def current_customer
    @current_customer ||= Customer.find_by(id: session[:customer_id]) if session[:customer_id]
  end

  def sign_in_customer(customer)
    session[:customer_id] = customer.id
    @current_customer = customer
  end

  def sign_out_customer
    session[:customer_id] = nil
    @current_customer = nil
  end

  def ensure_customer_role
    # Check if this is a login/register page - don't enforce role
    return if action_name == 'new' || action_name == 'create'

    if current_customer.blank?
      redirect_to customer_login_path, alert: 'Access denied. Customer account required.'
    end
  end

  # Cart helper methods
  def cart_count
    return 0 unless session[:cart].present? && session[:cart][:items].present?
    session[:cart][:items].sum { |item| item['quantity'].to_i }
  end

  # Override authorization check from ApplicationController
  def should_authorize?
    false # Never authorize customer controllers with CanCan
  end

  # Override mobile_api? to ensure customer controllers skip Devise authentication
  def mobile_api?
    true # Treat customer controllers like mobile API to skip Devise
  end

  # Make current_customer available in views
  helper_method :current_customer, :customer_signed_in?, :cart_count
end