class Admin::CustomerOrdersController < Admin::ApplicationController
  def index
    @customers = Customer.all.order(:row_number, :first_name, :last_name)
                          .includes(milk_subscriptions: :delivery_person)

    grouped = @customers.group_by(&:assigned_delivery_person)
    unassigned = grouped.delete(nil) || []
    assigned_groups = grouped.sort_by { |delivery_person, _| delivery_person.full_name }

    @delivery_groups = assigned_groups + [[nil, unassigned]]
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
