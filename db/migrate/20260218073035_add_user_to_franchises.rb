class AddUserToFranchises < ActiveRecord::Migration[8.0]
  def change
    add_reference :franchises, :user, null: false, foreign_key: true
  end
end
