module Spree
  class ProductImport < ActiveRecord::Base
    self.table_name = 'spree_imports'

    has_one :file, class_name: 'Spree::ImportFile', foreign_key: :spree_import_id
    has_many :import_items, as: :importable

    accepts_nested_attributes_for :file

    def import
      self.file.get_rows do |row|
        products << build_product(row)
      end
      products
    end

    def export(products)
      self.file.to_csv(products)
    end

    def import

    end

    private

    def build_product(attrs)
      @products << Spree::Product.where(id: attrs[:id]).first_or_create(attr)
    end

  end
end