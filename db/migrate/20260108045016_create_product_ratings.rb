class CreateProductRatings < ActiveRecord::Migration[8.0]
  def change
    # Create customers table if it doesn't exist
    unless table_exists?(:customers)
      create_table :customers do |t|
        t.string :first_name
        t.string :last_name
        t.string :email
        t.string :mobile
        t.timestamps
      end
    end

    create_table :product_ratings do |t|
      t.references :product, null: false, foreign_key: true
      t.references :customer, null: true, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.integer :rating, null: false
      t.text :comment
      t.integer :status, default: 0
      t.string :reviewer_name
      t.string :reviewer_email
      t.boolean :verified_purchase, default: false

      t.timestamps
    end

    add_index :product_ratings, [:product_id, :rating]
    add_index :product_ratings, [:product_id, :status]
  end
end
