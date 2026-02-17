class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]
  skip_before_action :set_cache_control_headers, only: [:new]
  skip_before_action :ensure_session_security
  skip_load_and_authorize_resource

  def new
    # Show login form
  end

  def create
    # Validate input parameters
    if params[:email].blank? || params[:password].blank?
      flash.now[:alert] = 'Please enter both email and password'
      render :new and return
    end

    user = User.find_by(email: params[:email].to_s.downcase.strip)

    if user&.valid_password?(params[:password])
      # Check if user is active/enabled
      unless user.status?
        flash.now[:alert] = 'Your account has been deactivated. Please contact support.'
        render :new and return
      end

      sign_in(user)

      # Enhanced session security markers
      current_session_id = session.id.to_s
      session[:user_authenticated] = user.id
      session[:session_id] = current_session_id
      session[:login_time] = Time.current.to_i
      session[:last_activity] = Time.current.to_i
      session[:login_ip] = request.remote_ip
      session[:user_agent_hash] = Digest::MD5.hexdigest(request.headers['User-Agent'].to_s)

      # Update user's last login info
      user.update_columns(
        last_login_at: Time.current,
        login_count: (user.login_count || 0) + 1,
        current_sign_in_at: Time.current,
        current_sign_in_ip: request.remote_ip
      )

      redirect_to after_sign_in_path_for(user), notice: 'Login successful!'
    else
      # More specific error messages
      if user.nil?
        flash.now[:alert] = 'No account found with this email address'
      else
        flash.now[:alert] = 'Incorrect password. Please try again.'
      end
      render :new
    end
  rescue => e
    Rails.logger.error "Login error: #{e.message}"
    flash.now[:alert] = 'Login failed. Please try again.'
    render :new
  end

  def destroy
    if current_user
      Rails.logger.info "User #{current_user.id} logging out from session #{session.id}"

      # Clear all session security markers
      session.delete(:user_authenticated)
      session.delete(:session_id)
      session.delete(:login_time)
      session.delete(:last_activity)
      session.delete(:login_ip)
      session.delete(:user_agent_hash)

      sign_out(current_user)
    end

    # Complete session reset and cache busting
    reset_session

    # Set headers to prevent back button access
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate, private, max-age=0'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = 'Thu, 01 Jan 1970 00:00:00 GMT'

    redirect_to new_sessions_path, notice: 'Logged out successfully!'
  end
end