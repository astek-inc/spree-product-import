class CreateSpreeImportFiles < ActiveRecord::Migration
  def change
    create_table :spree_import_files do |t|
      t.string :name
      t.string :path
      t.string :status, default: "pending"
      t.timestamp :imported_at
      t.timestamps null: false
    end
    add_belongs_to :spree_imports, :spree_import_id
  end
end
