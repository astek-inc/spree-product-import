module Spree
  class ProductImportItem < ActiveRecord::Base
    belongs_to :product_import
    belongs_to :product
    attr_accessor :state_label, :data
  end
end
