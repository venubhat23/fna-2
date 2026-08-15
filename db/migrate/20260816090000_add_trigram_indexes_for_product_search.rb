class AddTrigramIndexesForProductSearch < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')

    # products.name ILIKE '%term%' / products.sku ILIKE '%term%' (Product.search scope,
    # Customer::ShopController#index, Customer::ProductsController) can't use a plain
    # btree index because of the leading wildcard. A GIN trigram index does.
    add_index :products, :name, using: :gin, opclass: :gin_trgm_ops,
              algorithm: :concurrently, name: 'index_products_on_name_trigram'
    add_index :products, :sku, using: :gin, opclass: :gin_trgm_ops,
              algorithm: :concurrently, name: 'index_products_on_sku_trigram'
    add_index :categories, :name, using: :gin, opclass: :gin_trgm_ops,
              algorithm: :concurrently, name: 'index_categories_on_name_trigram'
  end

  def down
    remove_index :products, name: 'index_products_on_name_trigram', algorithm: :concurrently
    remove_index :products, name: 'index_products_on_sku_trigram', algorithm: :concurrently
    remove_index :categories, name: 'index_categories_on_name_trigram', algorithm: :concurrently
  end
end
