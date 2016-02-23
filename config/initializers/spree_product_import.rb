
Spree::ProductImport.setup do |config|
  config.brewster_ftp_server = ENV['BREWSTER_FTP_SERVER']
  config.brewster_ftp_username = ENV['BREWSTER_FTP_USERNAME']
  config.brewster_ftp_password = ENV['BREWSTER_FTP_PASSWORD']

  config.admin_product_imports_per_page = 15
end
