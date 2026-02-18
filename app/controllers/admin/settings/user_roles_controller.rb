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
    permitted_params = params.require(:user).permit(:first_name, :last_name, :email, :mobile, :password, :password_confirmation, :role_name, :original_password, sidebar_permissions: [], crud_permissions: {})

    # Handle CRUD permissions - store as JSON in sidebar_permissions field
    if params[:user][:crud_permissions].present?
      # Process CRUD permissions into a structured format
      crud_data = {}
      params[:user][:crud_permissions].each do |module_key, permissions|
        if permissions['all_access'] == '1'
          # For modules with "All Access" checked, grant all permissions
          crud_data[module_key] = {
            'view' => true,
            'create' => true,
            'edit' => true,
            'delete' => true
          }
        else
          # For modules with individual CRUD permissions (handle both "1" and "on" values)
          crud_data[module_key] = {
            'view' => ['1', 'on'].include?(permissions['view']),
            'create' => ['1', 'on'].include?(permissions['create']),
            'edit' => ['1', 'on'].include?(permissions['edit']),
            'delete' => ['1', 'on'].include?(permissions['delete'])
          }
        end
      end

      # Store CRUD permissions as JSON in sidebar_permissions field
      permitted_params[:sidebar_permissions] = crud_data.to_json
      # Clear the crud_permissions field to avoid confusion
      permitted_params[:crud_permissions] = nil
    elsif permitted_params[:sidebar_permissions].present?
      # Legacy format - convert array to JSON string for storage
      permitted_params[:sidebar_permissions] = permitted_params[:sidebar_permissions].compact_blank.to_json
    end

    permitted_params
  end

  def get_sidebar_options
    {
      'Main Menu' => [
        { key: 'dashboard', name: 'Dashboard' }
      ],
      'Sales' => [
        { key: 'bookings', name: 'Bookings' },
        { key: 'stores', name: 'Stores' }
      ],
      'Subscription' => [
        { key: 'subscriptions', name: 'Subscriptions' }
      ],
      'Inventory' => [
        { key: 'vendors', name: 'Vendors' },
        { key: 'vendor_purchases', name: 'Vendor Purchases' }
      ],
      'Master Data' => [
        { key: 'customers', name: 'Customers' },
        { key: 'categories', name: 'Categories' },
        { key: 'products', name: 'Products' },
        { key: 'customer_wallets', name: 'Customer Wallets' },
        { key: 'coupons', name: 'Coupons' },
        { key: 'franchises', name: 'Franchise' },
        { key: 'affiliates', name: 'Affiliate' }
      ],
      'Settings & Configuration' => [
        { key: 'system_settings', name: 'System Settings' },
        { key: 'banners', name: 'Banners' },
        { key: 'client_requests', name: 'Client Requests' }
      ]
    }
  end
end