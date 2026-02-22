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

    begin
      ActiveRecord::Base.transaction do
        # Save delivery person first
        @delivery_person.save!

        # Create associated User record for authentication
        user = User.new(
          first_name: @delivery_person.first_name,
          last_name: @delivery_person.last_name,
          email: @delivery_person.email,
          mobile: @delivery_person.mobile,
          user_type: 'delivery_person',
          address: @delivery_person.address,
          city: @delivery_person.city,
          state: @delivery_person.state,
          pincode: @delivery_person.pincode,
          status: @delivery_person.status
        )

        # Use the same password from delivery person
        user.password = delivery_person_params[:password]
        user.password_confirmation = delivery_person_params[:password_confirmation] || delivery_person_params[:password]

        user.save!

        redirect_to admin_delivery_person_path(@delivery_person),
                    notice: 'Delivery person and user account were successfully created.'
      end
    rescue ActiveRecord::RecordInvalid => e
      # Handle validation errors from either model
      if e.record.is_a?(DeliveryPerson)
        render :new, status: :unprocessable_entity
      else
        # User model validation failed
        @delivery_person.errors.add(:base, "User account creation failed: #{e.record.errors.full_messages.join(', ')}")
        render :new, status: :unprocessable_entity
      end
    rescue => e
      @delivery_person.errors.add(:base, "Creation failed: #{e.message}")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    begin
      ActiveRecord::Base.transaction do
        # Update delivery person
        @delivery_person.update!(delivery_person_params.except(:password, :password_confirmation))

        # Find and update associated User record
        user = User.find_by(email: @delivery_person.email, user_type: 'delivery_person')
        if user
          user.update!(
            first_name: @delivery_person.first_name,
            last_name: @delivery_person.last_name,
            email: @delivery_person.email,
            mobile: @delivery_person.mobile,
            address: @delivery_person.address,
            city: @delivery_person.city,
            state: @delivery_person.state,
            pincode: @delivery_person.pincode,
            status: @delivery_person.status
          )

          # Update password if provided
          if delivery_person_params[:password].present?
            user.password = delivery_person_params[:password]
            user.password_confirmation = delivery_person_params[:password_confirmation] || delivery_person_params[:password]
            user.save!
          end
        end

        redirect_to admin_delivery_person_path(@delivery_person),
                    notice: 'Delivery person and user account were successfully updated.'
      end
    rescue ActiveRecord::RecordInvalid => e
      if e.record.is_a?(DeliveryPerson)
        render :edit, status: :unprocessable_entity
      else
        @delivery_person.errors.add(:base, "User account update failed: #{e.record.errors.full_messages.join(', ')}")
        render :edit, status: :unprocessable_entity
      end
    rescue => e
      @delivery_person.errors.add(:base, "Update failed: #{e.message}")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    begin
      ActiveRecord::Base.transaction do
        # Find and delete associated User record
        user = User.find_by(email: @delivery_person.email, user_type: 'delivery_person')
        user&.destroy

        # Delete delivery person
        @delivery_person.destroy

        redirect_to admin_delivery_people_path,
                    notice: 'Delivery person and user account were successfully deleted.'
      end
    rescue => e
      redirect_to admin_delivery_people_path,
                  alert: "Failed to delete delivery person: #{e.message}"
    end
  end

  def toggle_status
    begin
      ActiveRecord::Base.transaction do
        new_status = !@delivery_person.status
        @delivery_person.update!(status: new_status)

        # Update associated User record status
        user = User.find_by(email: @delivery_person.email, user_type: 'delivery_person')
        user&.update!(status: new_status)

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
    rescue => e
      respond_to do |format|
        format.html { redirect_to admin_delivery_people_path, alert: "Failed to update status: #{e.message}" }
        format.json { render json: { error: "Failed to update status: #{e.message}" }, status: :unprocessable_entity }
      end
    end
  end

  def bulk_action
    delivery_person_ids = params[:delivery_person_ids]
    action = params[:bulk_action]

    return redirect_to admin_delivery_people_path, alert: 'Please select delivery people and an action.' if delivery_person_ids.blank? || action.blank?

    delivery_people = DeliveryPerson.where(id: delivery_person_ids)

    begin
      ActiveRecord::Base.transaction do
        case action
        when 'activate'
          delivery_people.update_all(status: true)
          # Update associated User records
          emails = delivery_people.pluck(:email)
          User.where(email: emails, user_type: 'delivery_person').update_all(status: true)
          redirect_to admin_delivery_people_path, notice: "#{delivery_people.count} delivery people activated successfully."
        when 'deactivate'
          delivery_people.update_all(status: false)
          # Update associated User records
          emails = delivery_people.pluck(:email)
          User.where(email: emails, user_type: 'delivery_person').update_all(status: false)
          redirect_to admin_delivery_people_path, notice: "#{delivery_people.count} delivery people deactivated successfully."
        when 'delete'
          count = delivery_people.count
          # Delete associated User records
          emails = delivery_people.pluck(:email)
          User.where(email: emails, user_type: 'delivery_person').destroy_all
          delivery_people.destroy_all
          redirect_to admin_delivery_people_path, notice: "#{count} delivery people deleted successfully."
        else
          redirect_to admin_delivery_people_path, alert: 'Invalid action selected.'
        end
      end
    rescue => e
      redirect_to admin_delivery_people_path, alert: "Bulk action failed: #{e.message}"
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