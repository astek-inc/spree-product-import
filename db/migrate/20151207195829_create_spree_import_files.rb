class CreateSpreeImportFiles < ActiveRecord::Migration
  def change
    create_table :spree_import_files do |t|
      t.string :name
      t.string :path
      t.string :file_type, default: "csv"
      t.string :status, default: "pending"
      t.references :spree_import
      t.timestamps null: false
    end

  end
end
