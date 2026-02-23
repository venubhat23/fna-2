class Affiliate::ApplicationController < ApplicationController
  layout 'affiliate'
  before_action :authenticate_affiliate!
  before_action :set_current_affiliate

  private

  def authenticate_affiliate!
    unless user_signed_in? && current_user.user_type == 'affiliate'
      redirect_to affiliate_login_path, alert: 'Please log in to access your affiliate account.'
    end
  end

  def set_current_affiliate
    if current_user&.user_type == 'affiliate'
      @current_affiliate = current_user.authenticatable
    end
  end

  def current_affiliate
    @current_affiliate
  end
  helper_method :current_affiliate
end