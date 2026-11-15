# Deletes a product together with every record that points at it, so the foreign keys
# on products (and the tables hanging off them) don't block the delete.
#
#   ProductDeletion.new(product).summary  # => [{ key:, label:, count:, action: 'delete'|'unlink' }, ...]
#   ProductDeletion.new(product).delete!  # one transaction
#
# Invoice items are kept and only unlinked from the product/its delivery tasks: they hold
# their own description/qty/price, so already-generated invoices stay correct.
class ProductDeletion
  # [key, label, action] - also the order the deletes run in (children before parents).
  ENTRIES = [
    [:invoice_items,         'Invoice line items (kept, unlinked from product)', 'unlink'],
    [:milk_delivery_tasks,   'Milk delivery tasks',                               'delete'],
    [:milk_subscriptions,    'Milk subscriptions',                                'delete'],
    [:customer_formats,      'Customer formats',                                  'delete'],
    [:subscription_templates,'Subscription templates',                            'delete'],
    [:booking_schedules,     'Booking schedules',                                 'delete'],
    [:booking_items,         'Booking (order) items',                             'delete'],
    [:order_items,           'Order items',                                       'delete'],
    [:sale_items,            'Sale items',                                        'delete'],
    [:stock_batches,         'Stock batches',                                     'delete'],
    [:stock_movements,       'Stock movements',                                   'delete'],
    [:vendor_purchase_items, 'Vendor purchase items',                             'delete'],
    [:delivery_rules,        'Delivery rules',                                    'delete'],
    [:product_reviews,       'Product reviews',                                   'delete'],
    [:product_ratings,       'Product ratings',                                   'delete'],
    [:wishlists,             'Wishlist entries',                                  'delete'],
    [:product_variants,      'Product variants',                                  'delete']
  ].freeze

  def initialize(product)
    @product = product
    @pid = product.id
  end

  # Counts for every associated table, in one round trip.
  def summary
    counts = BatchCount.call(**ENTRIES.to_h { |key, _, _| [key, relation(key)] })
    ENTRIES.map { |key, label, action| { key: key, label: label, count: counts[key], action: action } }
  end

  def delete!
    now = Time.current
    result = {}

    Product.transaction do
      ENTRIES.each do |key, _, action|
        result[key] =
          if key == :invoice_items
            unlink_invoice_items(now)
          elsif key == :booking_schedules
            # bookings.booking_schedule_id has a FK - keep the bookings, drop the link.
            Booking.where(booking_schedule_id: relation(:booking_schedules).select(:id))
                   .update_all(booking_schedule_id: nil, updated_at: now)
            relation(key).delete_all
          else
            relation(key).delete_all
          end
      end

      @product.destroy!
    end

    result
  end

  private

  def subscription_ids
    MilkSubscription.where(product_id: @pid).select(:id)
  end

  def task_ids
    relation(:milk_delivery_tasks).select(:id)
  end

  def relation(key)
    case key
    when :invoice_items
      InvoiceItem.where(product_id: @pid).or(InvoiceItem.where(milk_delivery_task_id: task_ids))
    when :milk_delivery_tasks
      MilkDeliveryTask.where(product_id: @pid).or(MilkDeliveryTask.where(subscription_id: subscription_ids))
    when :sale_items
      SaleItem.where(product_id: @pid).or(SaleItem.where(stock_batch_id: StockBatch.where(product_id: @pid).select(:id)))
    when :milk_subscriptions     then MilkSubscription.where(product_id: @pid)
    when :customer_formats       then CustomerFormat.where(product_id: @pid)
    when :subscription_templates then SubscriptionTemplate.where(product_id: @pid)
    when :booking_schedules      then BookingSchedule.where(product_id: @pid)
    when :booking_items          then BookingItem.where(product_id: @pid)
    when :order_items            then OrderItem.where(product_id: @pid)
    when :stock_batches          then StockBatch.where(product_id: @pid)
    when :stock_movements        then StockMovement.where(product_id: @pid)
    when :vendor_purchase_items  then VendorPurchaseItem.where(product_id: @pid)
    when :delivery_rules         then DeliveryRule.where(product_id: @pid)
    when :product_reviews        then ProductReview.where(product_id: @pid)
    when :product_ratings        then ProductRating.where(product_id: @pid)
    when :wishlists              then Wishlist.where(product_id: @pid)
    when :product_variants       then ProductVariant.where(product_id: @pid)
    end
  end

  # Clears both links in one statement (CASE keeps the other column as-is).
  def unlink_invoice_items(now)
    task_id_sql = task_ids.to_sql
    relation(:invoice_items).update_all([
      "product_id = CASE WHEN product_id = :pid THEN NULL ELSE product_id END, " \
      "milk_delivery_task_id = CASE WHEN milk_delivery_task_id IN (#{task_id_sql}) THEN NULL ELSE milk_delivery_task_id END, " \
      "updated_at = :now",
      { pid: @pid, now: now }
    ])
  end
end
