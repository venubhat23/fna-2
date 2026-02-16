class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]
  skip_before_action :set_cache_control_headers, only: [:new]
  skip_before_action :ensure_session_security

  def new
    # Show login form
  end

  def create
    user = User.find_by(email: params[:email])

    if user&.valid_password?(params[:password])
      sign_in(user)

      # Set session security markers
      session[:user_authenticated] = user.id
      session[:login_time] = Time.current.to_i
      session[:last_activity] = Time.current.to_i

      # Update user's last login info
      user.update_columns(
        last_login_at: Time.current,
        login_count: (user.login_count || 0) + 1,
        current_sign_in_at: Time.current,
        current_sign_in_ip: request.remote_ip
      )

      redirect_to after_sign_in_path_for(user), notice: 'Login successful!'
    else
      flash.now[:alert] = 'Invalid email or password'
      render :new
    end
  end

  def destroy
    if current_user
      # Clear session security markers
      session.delete(:user_authenticated)
      session.delete(:login_time)
      session.delete(:last_activity)

      sign_out(current_user)
    end

    # Clear all session data and reset session
    reset_session

    redirect_to new_sessions_path, notice: 'Logged out successfully!'
  end
end