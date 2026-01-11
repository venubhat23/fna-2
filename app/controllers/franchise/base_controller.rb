class Franchise::BaseController < ApplicationController
  layout 'franchise'

  before_action :authenticate_franchise

  private

  def authenticate_franchise
    unless current_franchise
      redirect_to franchise_login_path, alert: 'Please log in to continue'
    end
  end

  def current_franchise
    @current_franchise ||= Franchise.find_by(id: session[:franchise_id]) if session[:franchise_id]
  end

  helper_method :current_franchise
end