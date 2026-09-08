class Admin::CustomerOrdersController < Admin::ApplicationController
  def index
    @customers = Customer.all.order(:row_number, :first_name, :last_name)
                          .includes(milk_subscriptions: :delivery_person)

    grouped = @customers.group_by(&:assigned_delivery_person)
    unassigned = grouped.delete(nil) || []
    assigned_groups = grouped.sort_by { |delivery_person, _| delivery_person.full_name }

    @delivery_groups = assigned_groups + [[nil, unassigned]]

    @delivery_people = DeliveryPerson.where(status: true).order(:first_name, :last_name)
  end

  # Assigns (or clears) the delivery person for every subscription / task / format
  # belonging to a customer, so the customer moves between delivery groups.
  def assign_delivery_person
    customer = Customer.find(params[:id])
    delivery_person_id = params[:delivery_person_id].presence

    if delivery_person_id && !DeliveryPerson.exists?(id: delivery_person_id)
      return render json: { success: false, message: 'Delivery person not found.' }, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      customer.milk_subscriptions.update_all(delivery_person_id: delivery_person_id)
      customer.milk_delivery_tasks.update_all(delivery_person_id: delivery_person_id)
      SubscriptionTemplate.where(customer_id: customer.id).update_all(delivery_person_id: delivery_person_id) if defined?(SubscriptionTemplate)
      # customer_formats.delivery_person_id is NOT NULL, so only touch it when assigning.
      if delivery_person_id && defined?(CustomerFormat)
        CustomerFormat.where(customer_id: customer.id).update_all(delivery_person_id: delivery_person_id)
      end
    end

    name = delivery_person_id ? DeliveryPerson.find_by(id: delivery_person_id)&.full_name : nil
    render json: { success: true, message: name ? "Assigned to #{name}." : 'Delivery person removed.', delivery_person_name: name }
  rescue => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end

  def update
    @customer = Customer.find(params[:id])
    if @customer.update(row_number: params[:row_number].presence)
      render json: { success: true, message: 'Row number updated.' }
    else
      render json: { success: false, message: @customer.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def bulk_update
    updates = params[:customers] || []
    errors = []

    ActiveRecord::Base.transaction do
      updates.each do |item|
        customer = Customer.find_by(id: item[:id])
        next unless customer
        unless customer.update(row_number: item[:row_number].presence)
          errors << "Customer #{customer.display_name}: #{customer.errors.full_messages.join(', ')}"
        end
      end
      raise ActiveRecord::Rollback if errors.any?
    end

    if errors.any?
      render json: { success: false, message: errors.join('; ') }, status: :unprocessable_entity
    else
      render json: { success: true, message: 'Row numbers updated successfully.' }
    end
  end

  def clear_row_number
    @customer = Customer.find(params[:id])
    @customer.update_column(:row_number, nil)
    render json: { success: true, message: 'Row number cleared.' }
  end
end
