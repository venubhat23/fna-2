# Indexes found missing during an app-wide N+1 / slow-query scan.
# Built CONCURRENTLY so they don't lock writes in production.
class AddAppWidePerfIndexes < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    # Admin::CustomerWalletsController#index (latest transaction per wallet, DISTINCT ON)
    # and wallet show/history pages (wallet_transactions.recent).
    add_index :wallet_transactions, [:customer_wallet_id, :created_at],
              name: 'idx_wallet_txns_wallet_created_at',
              algorithm: :concurrently, if_not_exists: true

    # Admin::OrdersController#index orders by created_at DESC (Order.recent) with no index.
    add_index :orders, :created_at,
              algorithm: :concurrently, if_not_exists: true

    # GenerateFromCustomerFormat / CopyFromLastMonth look up the month's subscription per
    # customer+product+start_date once per format.
    add_index :milk_subscriptions, [:customer_id, :product_id, :start_date],
              name: 'idx_milk_subs_customer_product_start',
              algorithm: :concurrently, if_not_exists: true

    # Customer search boxes use ILIKE '%term%', which can't use a btree index.
    # pg_trgm is already enabled (see schema.rb).
    add_index :customers, :first_name, using: :gin, opclass: :gin_trgm_ops,
              name: 'idx_customers_first_name_trgm',
              algorithm: :concurrently, if_not_exists: true
    add_index :customers, :last_name, using: :gin, opclass: :gin_trgm_ops,
              name: 'idx_customers_last_name_trgm',
              algorithm: :concurrently, if_not_exists: true
    add_index :customers, :mobile, using: :gin, opclass: :gin_trgm_ops,
              name: 'idx_customers_mobile_trgm',
              algorithm: :concurrently, if_not_exists: true

    # Foreign keys that had no index (association lookups / dependent deletes scan the table).
    add_index :bookings, :subscription_id,
              algorithm: :concurrently, if_not_exists: true
    add_index :users, :reporting_manager_id,
              algorithm: :concurrently, if_not_exists: true
    add_index :sub_agents, :distributor_id,
              algorithm: :concurrently, if_not_exists: true
  end
end
