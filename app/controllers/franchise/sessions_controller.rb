class Franchise::SessionsController < ApplicationController
  layout 'public'

  before_action :redirect_if_authenticated, only: [:new, :create]
  before_action :authenticate_franchise, only: [:destroy]

  def new
    @franchise = Franchise.new
  end

  def create
    @franchise = Franchise.find_by(email: franchise_params[:email])

    if @franchise&.authenticate(franchise_params[:password])
      if @franchise.active?
        session[:franchise_id] = @franchise.id
        session[:franchise_type] = 'franchise'
        redirect_to franchise_dashboard_path, notice: 'Successfully logged in!'
      else
        flash.now[:alert] = 'Your franchise account is inactive. Please contact administrator.'
        render :new
      end
    else
      flash.now[:alert] = 'Invalid email or password'
      render :new
    end
  end

  def destroy
    session[:franchise_id] = nil
    session[:franchise_type] = nil
    redirect_to franchise_login_path, notice: 'Successfully logged out!'
  end

  private

  def franchise_params
    params.require(:franchise).permit(:email, :password)
  end

  def redirect_if_authenticated
    if current_franchise
      redirect_to franchise_dashboard_path
    end
  end

  def authenticate_franchise
    unless current_franchise
      redirect_to franchise_login_path, alert: 'Please log in to continue'
    end
  end

  def current_franchise
    @current_franchise ||= Franchise.find_by(id: session[:franchise_id]) if session[:franchise_id]
  end
end