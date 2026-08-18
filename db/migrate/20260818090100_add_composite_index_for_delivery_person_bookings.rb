class AddCompositeIndexForDeliveryPersonBookings < ActiveRecord::Migration[8.0]
  def change
    # Api::V1::Mobile::DeliveryController#tasks_today filters bookings by
    # delivery_person_id + today's date on every delivery-person app load.
    # bookings already has separate single-column indexes on delivery_person_id
    # and created_at (see db/schema.rb) but no composite, forcing a bitmap-AND
    # instead of a direct narrowing scan. The query wraps created_at in DATE(...),
    # which still can't use a plain btree range on the second column, but leading
    # with delivery_person_id narrows to one driver's bookings before that filter
    # runs, which is the expensive part today.
    #
    # NOT run yet - written for review, same as the leads index migration.
    add_index :bookings, [:delivery_person_id, :created_at], name: "index_bookings_on_delivery_person_id_and_created_at"
  end
end
