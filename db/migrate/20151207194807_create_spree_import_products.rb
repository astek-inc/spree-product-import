class CreateSpreeImportProducts < ActiveRecord::Migration
  def change
    create_table :spree_import_products do |t|
      t.string :status, default: "pending"
      t.timestamps null: false
      t.references :spree_product
      t.references :spree_import
    end
  end
end
