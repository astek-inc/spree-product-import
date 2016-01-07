Spree::Product.class_eval do
  has_many :product_import_items, :dependent => :destroy
end
