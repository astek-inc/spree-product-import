class AddProductImportImageServerIdToSpreeProductImports < ActiveRecord::Migration
  def change
    add_column :spree_product_imports, :product_import_image_server_id, :integer
    add_index :spree_product_imports, :product_import_image_server_id
  end
end
