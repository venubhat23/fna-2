class Admin::FamilyMembersController < Admin::ApplicationController
  before_action :set_customer
  before_action :set_family_member, only: [:show, :edit, :update, :destroy]

  # GET /admin/customers/:customer_id/family_members
  def index
    @family_members = @customer.family_members.order(:created_at)
  end

  # GET /admin/customers/:customer_id/family_members/1
  def show
  end

  # GET /admin/customers/:customer_id/family_members/new
  def new
    @family_member = @customer.family_members.build
  end

  # GET /admin/customers/:customer_id/family_members/1/edit
  def edit
  end

  # POST /admin/customers/:customer_id/family_members
  def create
    @family_member = @customer.family_members.build(family_member_params)

    if @family_member.save
      redirect_to admin_customer_family_member_path(@customer, @family_member), notice: 'Family member was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /admin/customers/:customer_id/family_members/1
  def update
    if @family_member.update(family_member_params)
      redirect_to admin_customer_family_member_path(@customer, @family_member), notice: 'Family member was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/customers/:customer_id/family_members/1
  def destroy
    @family_member.destroy
    redirect_to admin_customer_family_members_path(@customer), notice: 'Family member was successfully deleted.'
  end

  private

  def set_customer
    @customer = Customer.find(params[:customer_id])
  end

  def set_family_member
    @family_member = @customer.family_members.find(params[:id])
  end

  def family_member_params
    params.require(:family_member).permit(
      :first_name, :middle_name, :last_name, :birth_date, :age, :height, :weight, :gender, :relationship,
      :pan_no, :mobile, documents: []
    )
  end
end