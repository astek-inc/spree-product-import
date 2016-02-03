class CreateSpreeProductImportImageLocations < ActiveRecord::Migration
  def change
    create_table :spree_product_import_image_locations do |t|
      t.belongs_to :product_import
      t.string :path
      t.string :filename_pattern
      t.timestamps null: false
    end
    add_foreign_key :spree_product_import_image_locations, :spree_product_imports, column: :product_import_id
  end
end
