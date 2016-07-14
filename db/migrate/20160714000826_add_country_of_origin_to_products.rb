class AddCountryOfOriginToProducts < ActiveRecord::Migration
  def change
    add_column :spree_products, :country_of_origin, :integer
    add_foreign_key :spree_products, :spree_countries, column: :country_of_origin
  end
end
