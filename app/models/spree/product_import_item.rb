module Spree
  class ProductImportItem < Spree::Base

    STATE_PENDING = 'pending'
    STATE_IMPORTED = 'imported'
    STATE_ERROR = 'error'

    PUBLISH_STATE_PENDING = 'pending'
    PUBLISH_STATE_PUBLISHED = 'published'

    belongs_to :product_import
    belongs_to :product

    attr_accessor :state_label, :data

  end
end
