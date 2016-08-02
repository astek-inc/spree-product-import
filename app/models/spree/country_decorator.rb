Spree::Country.class_eval do
  has_many :products, foreign_key: :country_of_origin
end
