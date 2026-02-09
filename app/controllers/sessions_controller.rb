class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]

  def new
    # Show login form
  end

  def create
    user = User.find_by(email: params[:email])

    if user&.valid_password?(params[:password])
      sign_in(user)
      redirect_to dashboard_path, notice: 'Login successful!'
    else
      flash.now[:alert] = 'Invalid email or password'
      render :new
    end
  end

  def destroy
    sign_out(current_user)
    redirect_to new_sessions_path, notice: 'Logged out successfully!'
  end
end