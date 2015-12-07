class CreateSpreeImports < ActiveRecord::Migration
  def change
    create_table :spree_imports do |t|
      t.string :user
      t.string :status

      t.timestamps null: false
    end
  end
end
