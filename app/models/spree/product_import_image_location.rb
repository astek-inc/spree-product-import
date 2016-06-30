module Spree
  class ProductImportImageLocation < Spree::Base
    belongs_to :product_import
    acts_as_list scope: :product_import
    default_scope { order('position') }
  end
end
