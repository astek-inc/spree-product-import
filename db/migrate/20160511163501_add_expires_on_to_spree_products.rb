class AddExpiresOnToSpreeProducts < ActiveRecord::Migration
  def change
    add_column :spree_products, :expires_on, :datetime
    add_index :spree_products, :expires_on
  end
end
