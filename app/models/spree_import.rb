module Spree
  class Import < ActiveRecord::Base
    has_one  :import_file
    has_many :import_products
  end
end