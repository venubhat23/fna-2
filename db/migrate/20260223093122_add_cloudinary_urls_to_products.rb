class AddCloudinaryUrlsToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :image_url, :string
    add_column :products, :additional_images_urls, :text
  end
end
