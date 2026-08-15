class AddIndexesForVendorPurchasesAndBannersPerformance < ActiveRecord::Migration[8.0]
  def change
    # Vendor.active (used on every vendor_purchases new/edit/index request) filters
    # by status with no index on the boolean column.
    add_index :vendors, :status

    # admin/vendor_purchases#index sorts by created_at (VendorPurchase.recent) on
    # every request, unindexed.
    add_index :vendor_purchases, :created_at

    # admin/banners#index computes a "current" stats bucket by scanning both date
    # columns on every request.
    add_index :banners, [:display_start_date, :display_end_date]
  end
end
