class AddDaysToCustomerFormats < ActiveRecord::Migration[8.0]
  def change
    add_column :customer_formats, :days, :text
  end
end
