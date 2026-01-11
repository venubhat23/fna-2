class Affiliate::SessionsController < ApplicationController
  layout 'public'

  before_action :redirect_if_authenticated, only: [:new, :create]
  before_action :authenticate_affiliate, only: [:destroy]

  def new
    @affiliate = SubAgent.new
  end

  def create
    @affiliate = SubAgent.find_by(email: affiliate_params[:email])

    if @affiliate&.authenticate(affiliate_params[:password])
      if @affiliate.status?
        session[:affiliate_id] = @affiliate.id
        session[:affiliate_type] = 'affiliate'
        redirect_to affiliate_dashboard_path, notice: 'Successfully logged in!'
      else
        flash.now[:alert] = 'Your affiliate account is inactive. Please contact administrator.'
        render :new
      end
    else
      flash.now[:alert] = 'Invalid email or password'
      render :new
    end
  end

  def destroy
    session[:affiliate_id] = nil
    session[:affiliate_type] = nil
    redirect_to affiliate_login_path, notice: 'Successfully logged out!'
  end

  private

  def affiliate_params
    params.require(:sub_agent).permit(:email, :password)
  end

  def redirect_if_authenticated
    if current_affiliate
      redirect_to affiliate_dashboard_path
    end
  end

  def authenticate_affiliate
    unless current_affiliate
      redirect_to affiliate_login_path, alert: 'Please log in to continue'
    end
  end

  def current_affiliate
    @current_affiliate ||= SubAgent.find_by(id: session[:affiliate_id]) if session[:affiliate_id]
  end
end