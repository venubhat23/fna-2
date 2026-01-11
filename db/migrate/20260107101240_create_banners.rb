class CreateBanners < ActiveRecord::Migration[8.0]
  def change
    create_table :banners do |t|
      t.string :title
      t.text :description
      t.string :redirect_link
      t.date :display_start_date
      t.date :display_end_date
      t.string :display_location
      t.boolean :status, default: true
      t.integer :display_order, default: 0
      t.string :image

      t.timestamps
    end

    add_index :banners, :display_location
    add_index :banners, :status
    add_index :banners, :display_order
  end
end
