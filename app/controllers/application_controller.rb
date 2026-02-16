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
    # Strong cache prevention for all authenticated pages
    if user_signed_in?
      response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate, private, max-age=0'
      response.headers['Pragma'] = 'no-cache'
      response.headers['Expires'] = 'Thu, 01 Jan 1970 00:00:00 GMT'

      # Additional headers to prevent browser caching
      response.headers['Last-Modified'] = Time.current.httpdate
      response.headers['ETag'] = SecureRandom.hex(16)
    end
  end

  def ensure_session_security
    # Enhanced session security with multiple validation layers
    if user_signed_in? && current_user
      # Validate session integrity
      current_session_id = session.id.to_s
      stored_session_id = session[:session_id]

      # Check for session hijacking or replay attacks
      if stored_session_id && stored_session_id != current_session_id
        handle_session_security_breach
        return
      end

      # Set or verify session markers
      session[:session_id] = current_session_id
      session[:user_authenticated] = current_user.id
      session[:last_activity] = Time.current.to_i

      # Validate session age (prevent old session reuse)
      login_time = session[:login_time]
      if login_time && (Time.current.to_i - login_time) > 24.hours
        handle_session_expiry
        return
      end

      # Check for suspicious activity patterns
      if detect_suspicious_navigation?
        handle_suspicious_activity
        return
      end

    elsif !devise_controller? && !is_public_action?
      # Clear any stale session data for unauthenticated access
      clear_session_data
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

  def handle_session_security_breach
    Rails.logger.warn "Session security breach detected for user #{current_user&.id}: Session ID mismatch"
    clear_session_data
    sign_out(current_user) if current_user
    redirect_to new_sessions_path, alert: 'Security breach detected. Please login again.'
  end

  def handle_session_expiry
    Rails.logger.info "Session expired for user #{current_user&.id}"
    clear_session_data
    sign_out(current_user) if current_user
    redirect_to new_sessions_path, alert: 'Your session has expired. Please login again.'
  end

  def handle_suspicious_activity
    Rails.logger.warn "Suspicious navigation detected for user #{current_user&.id}"
    clear_session_data
    sign_out(current_user) if current_user
    redirect_to new_sessions_path, alert: 'Suspicious activity detected. Please login again.'
  end

  def detect_suspicious_navigation?
    # Check if user came from browser back/forward navigation after logout
    return false unless session[:last_activity]

    # Check for rapid navigation patterns (back button abuse)
    last_activity_time = session[:last_activity]
    current_time = Time.current.to_i

    # If more than 30 seconds of inactivity, require fresh validation
    if (current_time - last_activity_time) > 30
      # Check if this looks like a cached page access
      user_agent = request.headers['User-Agent']
      referer = request.headers['Referer']

      # Detect browser navigation patterns
      if referer.blank? || referer.include?('sign_in') || referer.include?('login')
        return true
      end
    end

    false
  end

  def clear_session_data
    session.delete(:user_authenticated)
    session.delete(:login_time)
    session.delete(:last_activity)
    session.delete(:session_id)
  end
end
