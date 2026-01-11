class RemoveParentIdFromCategories < ActiveRecord::Migration[8.0]
  def change
    remove_column :categories, :parent_id, :integer
  end
end
