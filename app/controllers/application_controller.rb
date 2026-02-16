class ApplicationController < ActionController::Base
  # Browser compatibility check disabled - allow all browsers
  # allow_browser versions: :modern

  # Include exception handler for API
  include ExceptionHandler

  # Security headers and cache control
  before_action :set_cache_control_headers
  before_action :ensure_session_security

  # Devise authentication
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Authorization
  load_and_authorize_resource unless: :devise_controller?, if: :should_authorize?

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: exception.message
  end

  protected

  def after_sign_in_path_for(resource)
    if resource.admin? || resource.user_type == 'admin'
      admin_bookings_path
    else
      admin_bookings_path  # Redirect all users to bookings page for now
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:login])
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :mobile, :user_type, :role, :status])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :mobile, :user_type, :role, :pan_number, :gst_number, :date_of_birth, :gender, :height, :weight, :education, :marital_status, :occupation, :job_name, :type_of_duty, :annual_income, :birth_place, :address, :state, :city])
  end

  def current_ability
    @current_ability ||= Ability.new(current_user)
  end

  def should_authorize?
    # Skip authorization for admin controllers if user is admin
    if self.class.name.start_with?('Admin::') && (current_user&.admin? || current_user&.user_type == 'admin')
      return false
    end
    true
  end

  private

  def set_cache_control_headers
    # Prevent caching for authenticated pages to avoid back button authentication bypass
    if user_signed_in?
      response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate, private'
      response.headers['Pragma'] = 'no-cache'
      response.headers['Expires'] = '0'
    end
  end

  def ensure_session_security
    # Force re-authentication if accessing protected pages after session expiry
    if user_signed_in? && current_user
      # Update last activity timestamp
      session[:last_activity] = Time.current.to_i

      # Check if this is a valid active session
      unless session[:user_authenticated] == current_user.id
        session[:user_authenticated] = current_user.id
      end
    elsif !devise_controller? && !is_public_action?
      # Clear any stale session data
      session.delete(:user_authenticated)
      session.delete(:last_activity)
    end
  end

  def is_public_action?
    # Define actions that don't require authentication
    public_controllers = [
      'sessions', 'devise/sessions', 'registrations', 'devise/registrations',
      'public_pages', 'api/cities'
    ]
    public_controllers.any? { |controller| self.class.name.downcase.include?(controller) }
  end
end
