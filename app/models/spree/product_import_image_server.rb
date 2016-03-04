module Spree
  class ProductImportImageServer < Spree::Base
    belongs_to :product_import
    default_scope { order(name: :asc) }
  end
end
