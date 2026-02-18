class Admin::FranchisesController < Admin::ApplicationController
  include ConfigurablePagination
  before_action :set_franchise, only: [:show, :edit, :update, :destroy, :toggle_status, :reset_password]

  def index
    @franchises = Franchise.all
    @franchises = @franchises.where("name ILIKE ? OR email ILIKE ? OR contact_person_name ILIKE ?",
                                   "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    @franchises = @franchises.where(status: params[:status]) if params[:status].present?
    @franchises = paginate_records(@franchises.order(:name))

    @stats = {
      total: Franchise.count,
      active: Franchise.where(status: true).count,
      inactive: Franchise.where(status: false).count
    }
  end

  def show
  end

  def new
    @franchise = Franchise.new
  end

  def create
    @franchise = Franchise.new(franchise_params)

    if @franchise.save
      # Create user account for franchise
      create_franchise_user
      redirect_to admin_franchise_path(@franchise), notice: 'Franchise was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @franchise.update(franchise_params)
      redirect_to admin_franchise_path(@franchise), notice: 'Franchise was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @franchise.destroy
    redirect_to admin_franchises_path, notice: 'Franchise was successfully deleted.'
  end

  def toggle_status
    @franchise.update!(status: !@franchise.status)
    redirect_to admin_franchises_path, notice: "Franchise #{@franchise.status? ? 'activated' : 'deactivated'} successfully."
  end

  def reset_password
    new_password = generate_secure_password(@franchise)

    if @franchise.user&.update(password: new_password, password_confirmation: new_password)
      @franchise.update(auto_generated_password: new_password)
      redirect_to admin_franchise_path(@franchise), notice: "Password reset successfully. New password: #{new_password}"
    else
      redirect_to admin_franchise_path(@franchise), alert: 'Failed to reset password.'
    end
  end

  private

  def set_franchise
    @franchise = Franchise.find(params[:id])
  end

  def franchise_params
    params.require(:franchise).permit(
      :name, :email, :mobile, :contact_person_name, :business_type,
      :address, :city, :state, :pincode, :pan_no, :gst_no, :license_no,
      :establishment_date, :territory, :franchise_fee, :commission_percentage,
      :status, :notes, :longitude, :latitude, :whatsapp_number
    )
  end

  def create_franchise_user
    password = generate_secure_password(@franchise)

    user = User.create!(
      first_name: @franchise.contact_person_name || @franchise.name,
      last_name: 'Franchise',
      email: @franchise.email,
      mobile: @franchise.mobile,
      password: password,
      password_confirmation: password,
      user_type: 'franchise',
      role: 'franchise',
      status: @franchise.status
    )

    @franchise.update(auto_generated_password: password, user: user)
  end

  def generate_secure_password(franchise)
    name_part = (franchise.contact_person_name || franchise.name)[0..3].upcase.ljust(4, 'X')
    year_part = Date.current.year.to_s
    "#{name_part}@#{year_part}"
  end
end
