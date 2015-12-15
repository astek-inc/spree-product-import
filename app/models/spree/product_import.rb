module Spree
  class ProductImport < ActiveRecord::Base
    attr_reader :products

    # TODO rename table spree_imports to spree_product_imports
    # then you can delete the following line.
    self.table_name = 'spree_imports'

    has_one :file, class_name: 'Spree::ImportFile', foreign_key: :spree_import_id
    has_many :import_items, as: :importable

    accepts_nested_attributes_for :file

    def initialize *args
      super
      @products ||= Array.new
    end

    def import
      @products = Array.new
      self.file.get_rows do |row|
        @products << build_product(row)
      end
      @products
    end

    # TODO Export implementation is incomplete
    def export(products)
      self.file.to_csv(products)
    end

    private

    def build_product(attrs)
      Spree::Product.where(id: attrs[:id]).first_or_create(attrs)
    end

  end
end