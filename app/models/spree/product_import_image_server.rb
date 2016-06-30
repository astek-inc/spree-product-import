module Spree
  class ProductImportImageServer < Spree::Base
    has_many :product_imports
    default_scope { order(name: :asc) }
    PROTOCOLS = [{name: 'http', label: 'HTTP (Web)'}, {name: 'ftp', label: 'FTP'}]
  end
end
