class Admin::AffiliatesController < Admin::ApplicationController
  include ConfigurablePagination
  before_action :set_affiliate, only: [:show, :edit, :update, :destroy, :toggle_status, :reset_password]

  def index
    @affiliates = Affiliate.all
    @affiliates = @affiliates.where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?",
                                   "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    @affiliates = @affiliates.where(status: params[:status]) if params[:status].present?
    @affiliates = paginate_records(@affiliates.order(:first_name))

    @stats = {
      total: Affiliate.count,
      active: Affiliate.active.count,
      inactive: Affiliate.inactive.count
    }
  end

  def show
  end

  def new
    @affiliate = Affiliate.new
  end

  def create
    @affiliate = Affiliate.new(affiliate_params)

    if @affiliate.save
      redirect_to admin_affiliate_path(@affiliate),
                 notice: "Affiliate created successfully. Login credentials: #{@affiliate.email} / #{@affiliate.auto_generated_password}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @affiliate.update(affiliate_params)
      redirect_to admin_affiliate_path(@affiliate), notice: 'Affiliate was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @affiliate.destroy
    redirect_to admin_affiliates_path, notice: 'Affiliate was successfully deleted.'
  end

  def toggle_status
    @affiliate.update!(status: !@affiliate.status)
    # Also update user status
    @affiliate.user&.update(status: @affiliate.status)
    redirect_to admin_affiliates_path, notice: "Affiliate #{@affiliate.status? ? 'activated' : 'deactivated'} successfully."
  end

  def reset_password
    new_password = @affiliate.send(:generate_secure_password)

    if @affiliate.user&.update(password: new_password, password_confirmation: new_password)
      @affiliate.update(auto_generated_password: new_password)
      redirect_to admin_affiliate_path(@affiliate), notice: "Password reset successfully. New password: #{new_password}"
    else
      redirect_to admin_affiliate_path(@affiliate), alert: 'Failed to reset password.'
    end
  end

  private

  def set_affiliate
    @affiliate = Affiliate.find(params[:id])
  end

  def affiliate_params
    params.require(:affiliate).permit(
      :first_name, :last_name, :middle_name, :email, :mobile,
      :address, :city, :state, :pincode, :pan_no, :gst_no,
      :commission_percentage, :bank_name, :account_no, :ifsc_code,
      :account_holder_name, :account_type, :upi_id, :status, :notes,
      :joining_date
    )
  end
end
