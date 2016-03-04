class PopulateProductImportImageServers < ActiveRecord::Migration
  def up
    [
        {name: 'Brewster', protocol: 'ftp', url: 'ftpimages.brewsterhomefashions.com', username: 'dealers', password: 'Brewster#1'},
        {name: 'Kravet', protocol: 'ftp', url: 'file.kravet.com', username: 'astek', password: 'Tla!0c'}
    ].each do |server|
      Spree::ProductImportImageServer.create(server)
    end

    server = Spree::ProductImportImageServer.find_by(name: 'Brewster')
    Spree::ProductImport.update_all(product_import_image_server_id: server.id)
  end

  def down
    Spree::ProductImport.update_all(product_import_image_server_id: nil)
    Spree::ProductImportImageServer.destroy_all
  end
end
