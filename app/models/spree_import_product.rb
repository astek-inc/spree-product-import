module Spree
  class ImportProduct < ActiveRecord::Base
    belongs_to :product
    belongs_to :import

  end
end