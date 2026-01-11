class Affiliate::BaseController < ApplicationController
  layout 'affiliate'

  before_action :authenticate_affiliate

  private

  def authenticate_affiliate
    unless current_affiliate
      redirect_to affiliate_login_path, alert: 'Please log in to continue'
    end
  end

  def current_affiliate
    @current_affiliate ||= SubAgent.find_by(id: session[:affiliate_id]) if session[:affiliate_id]
  end

  helper_method :current_affiliate
end