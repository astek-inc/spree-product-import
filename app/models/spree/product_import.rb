module Spree
  class ProductImport < Spree::Base

    STATE_PENDING = 'pending'
    STATE_COMPLETE = 'complete'

    # attr_reader :products
    attr_accessor :state_label

    belongs_to :product_import_image_server

    has_many :product_import_items, :dependent => :destroy
    has_many :product_import_image_locations, :dependent => :destroy

    validates :name, presence: true
    validates :product_import_image_server_id, presence: true

    has_attached_file :csv_file
    validates_attachment :csv_file, content_type: { content_type: ['text/plain', 'text/csv', 'text/comma-separated-values', 'application/vnd.ms-excel'] }

    mattr_accessor :brewster_ftp_server
    mattr_accessor :brewster_ftp_username
    mattr_accessor :brewster_ftp_password

    mattr_accessor :admin_product_imports_per_page

    default_scope { order(created_at: :desc) }

    self.whitelisted_ransackable_attributes =  %w[created_at]

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
