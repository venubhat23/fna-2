class MakeCustomerIdNullableInReferrals < ActiveRecord::Migration[8.0]
  def change
    change_column_null :referrals, :customer_id, true
  end
end
