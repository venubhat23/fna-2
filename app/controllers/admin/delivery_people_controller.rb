class Admin::DeliveryPeopleController < Admin::ApplicationController
  before_action :authenticate_user!
  before_action :set_delivery_person, only: [:show, :edit, :update, :destroy, :toggle_status]

  def index
    @delivery_people = DeliveryPerson.all

    # Apply search filter
    if params[:search].present? && params[:search].length >= 3
      @delivery_people = @delivery_people.search(params[:search])
    end

    # Apply vehicle type filter
    if params[:vehicle_type].present?
      @delivery_people = @delivery_people.by_vehicle_type(params[:vehicle_type])
    end

    # Apply status filter
    case params[:status]
    when 'active'
      @delivery_people = @delivery_people.active
    when 'inactive'
      @delivery_people = @delivery_people.inactive
    end

    # Apply city filter
    if params[:city].present?
      @delivery_people = @delivery_people.by_city(params[:city])
    end

    @delivery_people = @delivery_people.recent

    # Handle pagination if Kaminari is available
    if @delivery_people.respond_to?(:page)
      @delivery_people = @delivery_people.page(params[:page]).per(20)
    end

    # Statistics for cards
    @total_delivery_people = DeliveryPerson.count
    @active_delivery_people = DeliveryPerson.active.count
    @inactive_delivery_people = DeliveryPerson.inactive.count
    @vehicle_types_count = DeliveryPerson.group(:vehicle_type).count
    @total_filtered_count = @delivery_people.respond_to?(:total_count) ? @delivery_people.total_count : @delivery_people.count

    # Get unique cities for filter
    @cities = DeliveryPerson.distinct.pluck(:city).compact.sort
  end

  def show
    # Additional data for show page
  end

  def new
    @delivery_person = DeliveryPerson.new
  end

  def create
    @delivery_person = DeliveryPerson.new(delivery_person_params)

    if @delivery_person.save
      redirect_to admin_delivery_person_path(@delivery_person),
                  notice: 'Delivery person was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @delivery_person.update(delivery_person_params)
      redirect_to admin_delivery_person_path(@delivery_person),
                  notice: 'Delivery person was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @delivery_person.destroy
    redirect_to admin_delivery_people_path,
                notice: 'Delivery person was successfully deleted.'
  end

  def toggle_status
    @delivery_person.update(status: !@delivery_person.status)

    respond_to do |format|
      format.html { redirect_to admin_delivery_people_path }
      format.json {
        render json: {
          status: @delivery_person.status,
          message: "Delivery person #{@delivery_person.status ? 'activated' : 'deactivated'} successfully"
        }
      }
    end
  end

  def bulk_action
    delivery_person_ids = params[:delivery_person_ids]
    action = params[:bulk_action]

    return redirect_to admin_delivery_people_path, alert: 'Please select delivery people and an action.' if delivery_person_ids.blank? || action.blank?

    delivery_people = DeliveryPerson.where(id: delivery_person_ids)

    case action
    when 'activate'
      delivery_people.update_all(status: true)
      redirect_to admin_delivery_people_path, notice: "#{delivery_people.count} delivery people activated successfully."
    when 'deactivate'
      delivery_people.update_all(status: false)
      redirect_to admin_delivery_people_path, notice: "#{delivery_people.count} delivery people deactivated successfully."
    when 'delete'
      count = delivery_people.count
      delivery_people.destroy_all
      redirect_to admin_delivery_people_path, notice: "#{count} delivery people deleted successfully."
    else
      redirect_to admin_delivery_people_path, alert: 'Invalid action selected.'
    end
  end

  private

  def set_delivery_person
    @delivery_person = DeliveryPerson.find(params[:id])
  end

  def delivery_person_params
    params.require(:delivery_person).permit(
      :first_name, :last_name, :email, :mobile, :vehicle_type, :vehicle_number,
      :license_number, :address, :city, :state, :pincode, :emergency_contact_name,
      :emergency_contact_mobile, :joining_date, :salary, :status, :bank_name,
      :account_no, :ifsc_code, :account_holder_name, :delivery_areas, :notes,
      :password, :password_confirmation,
      :profile_picture, :license_document, :vehicle_document,
      delivery_area_list: []
    )
  end
end