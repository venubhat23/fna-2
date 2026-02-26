class Admin::BusinessSettingsController < Admin::ApplicationController
  before_action :set_business_settings

  def show
    # Display current business settings
  end

  def edit
    # Edit business settings
  end

  def update
    if @business_settings.class.update_business_settings(business_settings_params)
      redirect_to admin_business_settings_path, notice: 'Business settings updated successfully.'
    else
      render :edit, alert: 'Failed to update business settings.'
    end
  end

  private

  def set_business_settings
    @business_settings = SystemSetting.business_settings
  end

  def business_settings_params
    params.require(:business_settings).permit(
      :business_name,
      :address,
      :mobile,
      :email,
      :gstin,
      :pan_number,
      :account_holder_name,
      :bank_name,
      :account_number,
      :ifsc_code,
      :upi_id,
      :terms_and_conditions
    )
  end
end