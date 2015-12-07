class CreateSpreeImportProducts < ActiveRecord::Migration
  def change
    create_table :spree_import_products do |t|
      t.string :status, default: "pending"
      t.timestamps null: false
    end
    add_belongs_to :spree_products, :spree_product_id
    add_belongs_to :spree_imports, :spree_import_id
  end
end
