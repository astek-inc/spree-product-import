class PopulateProductImportImageServers < ActiveRecord::Migration
  def up
    [
        {name: 'Brewster', protocol: 'ftp', url: 'ftpimages.brewsterhomefashions.com', username: 'dealers', password: 'Brewster#1'},
        {name: 'Kravet', protocol: 'ftp', url: 'file.kravet.com', username: 'astek', password: 'Tla!0c'}
    ].each do |server|
      Spree::ProductImportImageServer.create(server)
    end
  end

  def down
    Spree::ProductImportImageServer.destroy_all
  end
end
