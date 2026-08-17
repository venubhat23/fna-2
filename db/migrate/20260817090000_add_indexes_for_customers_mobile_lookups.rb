class AddIndexesForCustomersMobileLookups < ActiveRecord::Migration[8.0]
  def change
    # Api::V1::Mobile::BaseController#authenticate_customer! runs on nearly every mobile
    # API request and does Customer.find_by(email:) / find_by(mobile:) as its primary
    # lookup path. Api::V1::Mobile::EcommerceController also does Customer.find_by(email:)
    # on orders, bookings, profile, update_profile, and save_location. Neither column is
    # indexed, so every one of those requests full-scans the customers table.
    #
    # NOT run yet - written for review, same as the delivery_people index migration.
    # Added as plain (non-unique) indexes: uniqueness hasn't been checked against live
    # data (no DB access without separate approval).
    add_index :customers, :email
    add_index :customers, :mobile
  end
end
