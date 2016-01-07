class CreateSpreeProductImports < ActiveRecord::Migration
  def change
    create_table :spree_product_imports do |t|
      t.string :name
      t.string :state, default: 'pending'
      t.datetime :completed_at
      t.timestamps null: false
    end
    add_attachment :spree_product_imports, :csv_file
  end
end
