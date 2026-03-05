class Customer::SupportController < Customer::BaseController
  skip_before_action :authenticate_customer!, only: [:index]
  skip_before_action :ensure_customer_role, only: [:index]

  def index
    # Support page with FAQ, contact info, etc.
  end
end