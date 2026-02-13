class AddIndexesForBookingPagePerformance < ActiveRecord::Migration[8.0]
  def change
    # Indexes for stock_batches table (crucial for performance)
    add_index :stock_batches, [:product_id, :status, :quantity_remaining],
              name: 'index_stock_batches_on_product_status_quantity'
    add_index :stock_batches, [:product_id, :batch_date, :created_at],
              name: 'index_stock_batches_on_product_fifo'

    # Indexes for products table
    add_index :products, [:status], name: 'index_products_on_status'
    add_index :products, [:category_id, :status], name: 'index_products_on_category_status'

    # Indexes for categories table
    add_index :categories, [:status], name: 'index_categories_on_status'

    # Indexes for customers for faster loading
    add_index :customers, [:first_name, :last_name], name: 'index_customers_on_name'

    # Indexes for active storage for image loading
    add_index :active_storage_attachments, [:record_type, :record_id, :name],
              name: 'index_active_storage_attachments_on_record_and_name'
  end
end
