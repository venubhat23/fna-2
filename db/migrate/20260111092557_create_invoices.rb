class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.string :invoice_number
      t.string :payout_type
      t.integer :payout_id
      t.decimal :total_amount
      t.string :status
      t.date :invoice_date
      t.date :due_date
      t.datetime :paid_at

      t.timestamps
    end
    add_index :invoices, :invoice_number, unique: true
  end
end
