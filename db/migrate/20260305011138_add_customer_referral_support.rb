class AddCustomerReferralSupport < ActiveRecord::Migration[8.0]
  def change
    add_reference :referrals, :referring_customer, null: true, foreign_key: { to_table: :customers }
    add_column :referrals, :referral_source, :string, default: 'affiliate'
    add_index :referrals, :referral_source

    # Make affiliate_id nullable since customer referrals won't have affiliates
    change_column_null :referrals, :affiliate_id, true
  end
end
