class CreateSpreeProductImportItems < ActiveRecord::Migration
  def change
    create_table :spree_product_import_items do |t|
      t.belongs_to :product
      t.belongs_to :product_import
      t.string :sku
      t.text :json
      t.string :state, default: 'pending'
      t.string :publish_state, default: 'pending'
      t.datetime :imported_at
      t.timestamps null: false
    end
    add_foreign_key :spree_product_import_items, :spree_products, column: :product_id
    add_foreign_key :spree_product_import_items, :spree_product_imports, column: :product_import_id
  end
end
