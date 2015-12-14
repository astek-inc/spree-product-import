class AddCsVfield < ActiveRecord::Migration
  def up
    add_attachment :spree_import_files, :csv_file
    rename_table :spree_import_item, :spree_import_items
  end

  def down
    remove_attachment :spree_import_files, :csv_file
    rename_table :spree_import_items, :spree_import_item
  end
end
