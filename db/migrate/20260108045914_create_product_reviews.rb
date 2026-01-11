class CreateProductReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :product_reviews do |t|
      t.references :product, null: false, foreign_key: true
      t.references :customer, null: true, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.integer :rating, null: false
      t.text :comment
      t.string :reviewer_name
      t.string :reviewer_email
      t.integer :status, default: 0
      t.boolean :verified_purchase, default: false
      t.integer :helpful_count, default: 0
      t.text :pros
      t.text :cons
      t.string :title
      t.json :images_data

      t.timestamps
    end

    add_index :product_reviews, [:product_id, :rating]
    add_index :product_reviews, [:product_id, :status]
    add_index :product_reviews, [:product_id, :created_at]
    add_index :product_reviews, [:customer_id, :product_id], unique: true, where: "customer_id IS NOT NULL"
  end
end
