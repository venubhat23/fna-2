class Admin::ProfilesController < Admin::ApplicationController
  before_action :set_user, only: [:show, :edit, :update]

  def show
    # Profile view with user information
  end

  def edit
    # Edit profile form
  end

  def update
    if @user.update(user_params)
      redirect_to admin_profile_path, notice: 'Profile updated successfully!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :middle_name, :email, :mobile,
      :birth_date, :gender, :pan_no, :aadhar_no, :gst_no,
      :company_name, :address, :city, :state, :pincode, :country,
      :emergency_contact_name, :emergency_contact_mobile,
      :department, :designation, :profile_picture
    )
  end
end