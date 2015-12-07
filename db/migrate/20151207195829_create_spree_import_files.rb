class CreateSpreeImportFiles < ActiveRecord::Migration
  def change
    create_table :spree_import_files do |t|
      t.string :name
      t.string :path

      t.timestamps null: false
    end
  end
end
