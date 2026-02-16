class AddImageBackupUrlToCategories < ActiveRecord::Migration[8.0]
  def change
    add_column :categories, :image_backup_url, :string
  end
end
