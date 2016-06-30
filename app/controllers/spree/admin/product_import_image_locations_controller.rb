module Spree::Admin
  class ProductImportImageLocationsController < ResourceController

    before_action :load_product_import, except: [:create, :update]

    # def index
    #   @product_import_image_locations = Spree::ProductImportImageLocation.where(product_import_id: params[:product_import_id])
    # end

    private

    def permitted_resource_params
      params.require(:product_import_image_location).permit(:id, :product_import_id, :path, :filename_pattern, :position)
    end

    def location_after_save
      load_product_import
      return admin_product_import_product_import_image_locations_url(@product_import)
    end

    def load_product_import
      @product_import = Spree::ProductImport.find(params[:product_import_id])
    end
  end
end
