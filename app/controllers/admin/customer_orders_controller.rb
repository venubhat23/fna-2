class Admin::CustomerOrdersController < Admin::ApplicationController
  def index
    @month = params[:month].presence || Date.current.strftime('%Y-%m')
    @customers = Customer.all.order(:row_number, :first_name, :last_name)
                          .includes(milk_subscriptions: :delivery_person)

    # Subscription count per [delivery_person_id, customer_id] for the view.
    @subscription_counts = Hash.new(0)

    month_start = parse_month(@month)
    if month_start
      # Same rules as Admin::SubscriptionsController (filter_by_month +
      # filter_by_delivery_person), so a delivery person's group here holds the same
      # subscriptions that page lists for that delivery person and month:
      #   - a subscription is in the month when it has a delivery task in the month
      #   - it belongs to every delivery person that appears on its tasks
      # A customer is listed once per delivery person, with their subscription count.
      @month_label = month_start.strftime('%B %Y')
      month_sub_ids = MilkDeliveryTask.where(delivery_date: month_start..month_start.end_of_month)
                                      .select(:subscription_id)
      customer_by_sub = MilkSubscription.where(id: month_sub_ids).pluck(:id, :customer_id).to_h
      dp_ids_by_sub = MilkDeliveryTask.where(subscription_id: customer_by_sub.keys)
                                      .where.not(delivery_person_id: nil)
                                      .distinct.pluck(:subscription_id, :delivery_person_id)
                                      .group_by(&:first).transform_values { |pairs| pairs.map(&:last) }

      customer_by_sub.each do |sub_id, customer_id|
        dp_ids = dp_ids_by_sub[sub_id].presence || [nil]
        dp_ids.each { |dp_id| @subscription_counts[[dp_id, customer_id]] += 1 }
      end

      people_by_id = DeliveryPerson.where(id: @subscription_counts.keys.map(&:first).compact.uniq).index_by(&:id)
      dp_ids_by_customer = @subscription_counts.keys.each_with_object(Hash.new { |h, k| h[k] = [] }) do |(dp_id, customer_id), h|
        h[customer_id] << dp_id
      end

      # Iterating @customers keeps its row_number/name ordering within each group.
      grouped = Hash.new { |h, k| h[k] = [] }
      @customers.where(id: dp_ids_by_customer.keys).each do |customer|
        dp_ids_by_customer[customer.id].each { |dp_id| grouped[dp_id && people_by_id[dp_id]] << customer }
      end
    else
      @month = 'all'
      grouped = @customers.group_by(&:assigned_delivery_person)
      sub_counts = MilkSubscription.group(:customer_id).count
      grouped.each do |delivery_person, customers|
        customers.each { |c| @subscription_counts[[delivery_person&.id, c.id]] = sub_counts[c.id] || 0 }
      end
    end

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

  private

  def parse_month(value)
    return nil if value == 'all'
    Date.strptime(value, '%Y-%m')
  rescue ArgumentError, TypeError
    Date.current.beginning_of_month
  end

end
