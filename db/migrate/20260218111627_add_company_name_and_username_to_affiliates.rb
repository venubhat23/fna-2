class AddCompanyNameAndUsernameToAffiliates < ActiveRecord::Migration[8.0]
  def change
    add_column :affiliates, :company_name, :string
    add_column :affiliates, :username, :string
  end
end
