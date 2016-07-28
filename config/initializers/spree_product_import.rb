require File.expand_path File.dirname(__FILE__)+'/../../lib/spree_product_imports/image'

Spree::ProductImport.setup do |config|
  config.admin_product_imports_per_page = 15
end
