class ModifyColumns < ActiveRecord::Migration
  def change
    drop_table :spree_import_products

    create_table :spree_import_item do |t|
      t.integer :item_id, null: false
      t.string :status, default: 'pending'
      t.references :importable, polymorphic: true, index: true
    end

  end
end
