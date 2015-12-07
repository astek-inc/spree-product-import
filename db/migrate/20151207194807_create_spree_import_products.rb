class CreateSpreeImportProducts < ActiveRecord::Migration
  def change
    create_table :spree_import_products do |t|

      t.timestamps null: false
    end
  end
end
