# Lets admin "Unassign Delivery Person" on a subscription clear the delivery person
# on the matching customer formats too.
class AllowNullDeliveryPersonOnCustomerFormats < ActiveRecord::Migration[8.0]
  def change
    change_column_null :customer_formats, :delivery_person_id, true
  end
end
