class Customer::SessionsController < Customer::BaseController
  skip_before_action :authenticate_customer!, except: [:destroy]
  skip_before_action :ensure_customer_role, except: [:destroy]
  layout 'customer_auth'

  def new
    # Check if customer is already signed in before showing login form
    if session[:customer_id].present? && Customer.find_by(id: session[:customer_id])
      redirect_to customer_root_path and return
    end
    # Show login form
  end

  def create
    customer = find_customer_by_credentials

    if customer&.authenticate(params[:password])
      sign_in_customer(customer)
      redirect_to customer_dashboard_path, notice: 'Successfully logged in!'
    else
      flash.now[:alert] = 'Invalid email/mobile or password.'
      render :new
    end
  end

  def destroy
    sign_out_customer
    redirect_to customer_login_path, notice: 'Successfully logged out!'
  end

  private

  def find_customer_by_credentials
    login = params[:email_or_mobile]&.strip&.downcase

    # Try email first
    customer = Customer.find_by('LOWER(email) = ?', login)

    # Try mobile if email not found
    if customer.nil? && login.present?
      formatted_mobile = normalize_mobile_for_search(login)
      customer = Customer.find_by(mobile: formatted_mobile) if formatted_mobile
    end

    customer
  end

  def normalize_mobile_for_search(mobile)
    return nil if mobile.blank?

    # Remove all non-digit characters
    clean_mobile = mobile.gsub(/\D/, '')

    # Handle different mobile number formats
    if clean_mobile.length == 10 && clean_mobile.match?(/\A[6-9]/)
      clean_mobile
    elsif clean_mobile.length == 12 && clean_mobile.start_with?('91')
      clean_mobile[2..-1]
    else
      nil
    end
  end
end