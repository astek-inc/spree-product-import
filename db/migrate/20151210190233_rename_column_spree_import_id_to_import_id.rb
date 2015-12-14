class RenameColumnSpreeImportIdToImportId < ActiveRecord::Migration
  def up
    rename_column :spree_import_files, :spree_import_id, :import_id
  end
  def down
    rename_column :spree_import_files, :import_id, :spree_import_id
  end

end
