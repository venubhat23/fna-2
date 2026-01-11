class AddPasswordDigestToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :password_digest, :string
  end
end
