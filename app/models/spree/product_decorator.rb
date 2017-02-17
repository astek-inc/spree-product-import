Spree::Product.class_eval do
  has_one :product_import_item
  belongs_to :country, foreign_key: :country_of_origin
end
