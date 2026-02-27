class CreatePendingAmounts < ActiveRecord::Migration[8.0]
  def change
    create_table :pending_amounts do |t|
      t.references :customer, null: false, foreign_key: true
      t.decimal :amount
      t.text :description
      t.date :pending_date
      t.integer :status
      t.text :notes

      t.timestamps
    end
  end
end
