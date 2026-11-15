# Deletes a delivery person together with everything that points at them, so the foreign
# keys on delivery_people don't block the delete.
#
#   DeliveryPersonDeletion.new(person).summary  # => [{ key:, label:, count:, action: 'delete'|'unlink' }, ...]
#   DeliveryPersonDeletion.new(person).delete!  # one transaction
#
# Customer-side records (bookings, delivery tasks, subscriptions, formats, templates) are
# kept and only unassigned - they belong to customers and just need a new delivery person.
# The person's device tokens and their login (User) account are deleted.
class DeliveryPersonDeletion
  # No app model for this table; a private one is enough to count/delete rows.
  class DeviceToken < ApplicationRecord
    self.table_name = 'device_tokens'
  end

  # [key, label, action] - also the order the changes run in.
  ENTRIES = [
    [:bookings,               'Bookings (kept, unassigned)',               'unlink'],
    [:milk_delivery_tasks,    'Milk delivery tasks (kept, unassigned)',    'unlink'],
    [:milk_subscriptions,     'Milk subscriptions (kept, unassigned)',     'unlink'],
    [:customer_formats,       'Customer formats (kept, unassigned)',       'unlink'],
    [:subscription_templates, 'Subscription templates (kept, unassigned)', 'unlink'],
    [:device_tokens,          'Device tokens',                             'delete'],
    [:user_accounts,          'Login account',                             'delete']
  ].freeze

  def initialize(delivery_person)
    @person = delivery_person
    @pid = delivery_person.id
  end

  # Counts for every associated table, in one round trip.
  def summary
    counts = BatchCount.call(**ENTRIES.to_h { |key, _, _| [key, relation(key)] })
    ENTRIES.map { |key, label, action| { key: key, label: label, count: counts[key], action: action } }
  end

  def delete!
    now = Time.current
    result = {}

    DeliveryPerson.transaction do
      ENTRIES.each do |key, _, action|
        result[key] =
          if key == :user_accounts
            # destroy (not delete_all) so User's own cleanup callbacks run.
            relation(key).to_a.each(&:destroy!).size
          elsif action == 'unlink'
            relation(key).update_all(delivery_person_id: nil, updated_at: now)
          else
            relation(key).delete_all
          end
      end

      @person.destroy!
    end

    result
  end

  private

  def relation(key)
    case key
    when :bookings               then Booking.where(delivery_person_id: @pid)
    when :milk_delivery_tasks    then MilkDeliveryTask.where(delivery_person_id: @pid)
    when :milk_subscriptions     then MilkSubscription.where(delivery_person_id: @pid)
    when :customer_formats       then CustomerFormat.where(delivery_person_id: @pid)
    when :subscription_templates then SubscriptionTemplate.where(delivery_person_id: @pid)
    when :device_tokens          then DeviceToken.where(delivery_person_id: @pid)
    when :user_accounts          then User.where(email: @person.email, user_type: 'delivery_person')
    end
  end
end
