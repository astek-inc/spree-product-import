module Spree::Admin
  class ProductImportImageServersController < ResourceController

    protected

    def permitted_resource_params
      params.require(:product_import_image_server).permit(:id, :product_import_id, :name, :protocol, :url, :username, :password)
    end

  end
end
