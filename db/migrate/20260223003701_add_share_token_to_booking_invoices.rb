class AddShareTokenToBookingInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :booking_invoices, :share_token, :string
    add_index :booking_invoices, :share_token, unique: true
  end
end
