class AddPasswordFieldsToDeliveryPeople < ActiveRecord::Migration[8.0]
  def change
    add_column :delivery_people, :password_digest, :string
    add_column :delivery_people, :auto_generated_password, :string
  end
end
