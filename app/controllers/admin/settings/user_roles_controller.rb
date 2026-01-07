class Admin::Settings::UserRolesController < Admin::Settings::BaseController
  include ConfigurablePagination
  before_action :set_user, only: [:show, :edit, :update, :destroy, :toggle_status]

  def index
    @users = User.where(user_type: ['admin', 'agent']).order(:created_at)
    @users = @users.where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    @users = paginate_records(@users)
  end

  def show
  end

  def new
    @user = User.new
    @sidebar_options = get_sidebar_options
  end

  def edit
    @sidebar_options = get_sidebar_options
  end

  def create
    @user = User.new(user_params)
    @user.user_type = 'admin'
    @user.status = true

    # Store the plain password temporarily for display (before it gets encrypted)
    plain_password = @user.password

    if @user.save
      # Store the original password for showing on the user details page
      @user.update_column(:original_password, plain_password) if plain_password.present?

      # Set special flash to indicate user was just created
      flash[:user_created] = true
      redirect_to admin_settings_user_role_path(@user), notice: 'User was successfully created.'
    else
      @sidebar_options = get_sidebar_options
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params)
      redirect_to admin_settings_user_role_path(@user), notice: 'User was successfully updated.'
    else
      @sidebar_options = get_sidebar_options
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    redirect_to admin_settings_user_roles_path, notice: 'User was successfully deleted.'
  end

  def toggle_status
    @user.update(status: !@user.status)
    redirect_to admin_settings_user_roles_path, notice: "User #{@user.status? ? 'activated' : 'deactivated'} successfully."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    permitted_params = params.require(:user).permit(:first_name, :last_name, :email, :mobile, :password, :password_confirmation, :role_name, sidebar_permissions: [])

    # Convert sidebar_permissions array to JSON string for storage
    if permitted_params[:sidebar_permissions].present?
      permitted_params[:sidebar_permissions] = permitted_params[:sidebar_permissions].compact_blank.to_json
    end

    permitted_params
  end

  def get_sidebar_options
    {
      'Main Menu' => [
        { key: 'dashboard', name: 'Dashboard' },
        { key: 'customers', name: 'Customers' },
        { key: 'sub_agents', name: 'Affiliate' },
        { key: 'distributors', name: 'Ambassadors' },
        { key: 'investors', name: 'Investors' }
      ],
      'Payouts & Commission' => [
        { key: 'affiliate_payouts', name: 'Affiliate Payouts' },
        { key: 'distributor_payouts', name: 'Ambassador Payouts' },
        { key: 'payouts', name: 'Payout' }
      ],
      'Business Partners' => [
        { key: 'brokers', name: 'Brokers' },
        { key: 'agency_codes', name: 'Agency Code' },
        { key: 'leads', name: 'Leads' }
      ],
      'Insurance Products' => [
        { key: 'life_insurance', name: 'Life Insurance' },
        { key: 'health_insurance', name: 'Health Insurance' },
        { key: 'motor_insurance', name: 'Motor Insurance' },
        { key: 'other_insurance', name: 'Other Insurance' }
      ],
      'Reports & Analytics' => [
        { key: 'commission_report', name: 'Commission Report' },
        { key: 'expired_insurance', name: 'Expired Insurance' },
        { key: 'payment_due', name: 'Payment Due' },
        { key: 'upcoming_renewal', name: 'Upcoming Renewal' },
        { key: 'upcoming_payment', name: 'Upcoming Payment' },
        { key: 'leads_report', name: 'Leads Report' },
        { key: 'session_report', name: 'Session Report' }
      ],
      'Management' => [
        { key: 'client_requests', name: 'Client Requests' },
        { key: 'insurance_companies', name: 'Companies' },
        { key: 'agency_brokers', name: 'Agency/Broker' },
        { key: 'banners', name: 'Banner Management' },
        { key: 'imports', name: 'Imports' },
        { key: 'roles_permissions', name: 'Roles & Permissions' }
      ],
      'Invoice' => [
        { key: 'invoices', name: 'Invoices' }
      ],
      'Settings' => [
        { key: 'user_roles', name: 'User Roles' },
        { key: 'system_settings', name: 'System Settings' }
      ]
    }
  end
end