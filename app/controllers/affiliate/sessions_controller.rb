class Affiliate::SessionsController < ApplicationController
  layout 'affiliate_auth'
  before_action :redirect_if_authenticated, only: [:new, :create]

  def new
    # Login form
  end

  def create
    @user = User.find_by(email: params[:email])

    if @user&.authenticate(params[:password]) && @user.user_type == 'affiliate'
      if @user.status? # Check if user is active
        session[:user_id] = @user.id
        redirect_to affiliate_root_path, notice: 'Welcome back!'
      else
        flash.now[:alert] = 'Your affiliate account has been deactivated. Please contact support.'
        render :new, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = 'Invalid email or password.'
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to affiliate_login_path, notice: 'You have been logged out.'
  end

  private

  def redirect_if_authenticated
    if user_signed_in? && current_user.user_type == 'affiliate'
      redirect_to affiliate_root_path
    end
  end
end