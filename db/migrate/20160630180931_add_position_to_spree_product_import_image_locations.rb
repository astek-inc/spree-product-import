class AddPositionToSpreeProductImportImageLocations < ActiveRecord::Migration
  def change
    add_column :spree_product_import_image_locations, :position, :integer, :default => 0
    add_index :spree_product_import_image_locations, :position
  end
end
