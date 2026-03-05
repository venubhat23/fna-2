class AddCollectFromStoreToSystemSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :system_settings, :collect_from_store_enabled, :boolean
  end
end
