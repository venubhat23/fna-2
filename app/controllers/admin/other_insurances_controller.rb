class Admin::OtherInsurancesController < Admin::ApplicationController
  before_action :set_other_insurance, only: [:show, :edit, :update, :destroy]

  def index
    @other_insurances = Policy.where(insurance_type: 'other').includes(:customer, :insurance_company)
    @other_insurances = @other_insurances.order(created_at: :desc).page(params[:page])
  end

  def show
  end

  def new
    @other_insurance = Policy.new(insurance_type: 'other')
    load_form_data
  end

  def edit
    load_form_data
  end

  def create
    @other_insurance = Policy.new(other_insurance_params)
    @other_insurance.insurance_type = 'other'
    @other_insurance.user = current_user

    if @other_insurance.save
      redirect_to admin_other_insurance_path(@other_insurance), notice: 'Other insurance policy was successfully created.'
    else
      @customers = Customer.active.order(:first_name)
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @other_insurance.update(other_insurance_params)
      redirect_to admin_other_insurance_path(@other_insurance), notice: 'Other insurance policy was successfully updated.'
    else
      @customers = Customer.active.order(:first_name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @other_insurance.destroy
    redirect_to admin_other_insurances_path, notice: 'Other insurance policy was successfully deleted.'
  end

  private

  def set_other_insurance
    @other_insurance = Policy.where(insurance_type: 'other').find(params[:id])
  end

  def load_form_data
    @customers = Customer.active.order(:first_name)
  end

  def other_insurance_params
    params.require(:policy).permit(
      :customer_id, :insurance_company_id, :policy_number, :policy_type,
      :sum_insured, :net_premium, :total_premium, :payment_mode, :gst_percentage,
      :policy_start_date, :policy_end_date, :policy_booking_date, :status, :note
    )
  end
end