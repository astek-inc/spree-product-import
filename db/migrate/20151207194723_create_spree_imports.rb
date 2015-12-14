class CreateSpreeImports < ActiveRecord::Migration
  def change
    create_table :spree_imports do |t|
      t.string :status
      t.datetime :imported_at
      t.timestamps null: false
    end
  end
end
pwd