module Spree
  class ProductImportImageServer < Spree::Base
    belongs_to :product_import
    default_scope { order(name: :asc) }
    PROTOCOLS = [{name: 'http', label: 'HTTP (Web)'}, {name: 'ftp', label: 'FTP'}]
  end
end
