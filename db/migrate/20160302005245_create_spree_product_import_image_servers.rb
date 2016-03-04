class CreateSpreeProductImportImageServers < ActiveRecord::Migration
  def change
    create_table :spree_product_import_image_servers do |t|
      t.string :name
      t.string :protocol
      t.string :url
      t.string :username
      t.string :password
      t.timestamps null: false
    end
  end
end
