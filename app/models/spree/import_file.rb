module Spree
  class ImportFile < ActiveRecord::Base
    require 'csv'
    require 'open-uri'

    belongs_to :product_import
    attr_accessor :template

    has_attached_file :csv_file
    validates_attachment :csv_file, content_type: { content_type: ['text/plain', 'text/csv'] }


    def self.to_csv(items, options = {})
      CSV.generate(options) do |csv|
        csv << item.column_names
        items.each do |item|
          csv << item.attribute.values_at(*item.column_names)
        end
      end
    end


    def get_rows &block
      CSV.new(open(self.csv_file.url), headers: true, header_converters: :symbol).each do |record|
        yield(record.to_h)
      end
    end

  end
end
