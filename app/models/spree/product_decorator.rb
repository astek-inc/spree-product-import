Spree::Product.class_eval do
  has_many :product_import_items, :dependent => :destroy
  belongs_to :country, foreign_key: :country_of_origin
end
