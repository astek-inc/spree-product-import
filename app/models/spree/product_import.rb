module Spree
  class ProductImport < Spree::Base

    STATE_PENDING = 'pending'
    STATE_COMPLETE = 'complete'

    # attr_reader :products
    attr_accessor :state_label

    has_many :product_import_items, :dependent => :destroy
    has_many :product_import_image_locations, :dependent => :destroy

    has_attached_file :csv_file
    validates_attachment :csv_file, content_type: { content_type: ['text/plain', 'text/csv'] }

    mattr_accessor :brewster_ftp_server
    mattr_accessor :brewster_ftp_username
    mattr_accessor :brewster_ftp_password

    # def initialize *args
    #   super
    #   @products ||= Array.new
    # end
    #
    # def import
    #   # @products = []
    #   # # self.csv_file.get_rows do |row|
    #   # #   @products << build_product(row)
    #   # # end
    #   # @products
    #   self.id
    # end

    #
    # # # TODO Export implementation is incomplete
    # # def export(products)
    # #   self.file.to_csv(products)
    # # end
    #
    # private
    #
    # def build_product(attrs)
    #   #Spree::Product.where(id: attrs[:id]).first_or_create(attrs)
    # end

    def self.setup
      yield self
    end

  end
end
