module Spree::Admin
  class ProductImportItemsController < ResourceController

    before_action :load_product_import, except: [:create, :update]
    # before_action :set_item_display_data, only: [:index]

    def index
      @product_import_items = Spree::ProductImportItem.where(product_import_id: params[:product_import_id])
      set_item_display_data
    end

    private

    def permitted_resource_params
      params.require(:product_import_item).
          permit(:id, :product_import_id, :product_id, :sku, :json, :state, :publish_state, :imported_at)
    end

    def load_product_import
      @product_import = Spree::ProductImport.find(params[:product_import_id])
    end

    # Extract data to a hash for simple output
    def set_item_display_data
      @item_display_data = @product_import_items.map { |item| set_display_data item }
    end

    # Create a hash of item data for simple output
    def set_display_data(item)
      data = JSON.parse(item.json)
      out = {
          'id' => item.id,
          'product_id' => item.product_id,
          'sku' => item.sku,
          'state' => item.state,
          'name' => data['item_name'],
          'brand' => data['brand'],
          'collection' => data['main_category'],
          'primary_category' => data['type'],
          # 'secondary_category' => data['secondary_category'].present? ? data['secondary_category'] : nil
      }

      case item.state
        when Spree::ProductImportItem::STATE_PENDING
          out['state_label'] = 'warning'
        when Spree::ProductImportItem::STATE_IMPORTED
          out['state_label'] = 'success'
        when Spree::ProductImportItem::STATE_ERROR
          out['state_label'] = 'error'
      end

      if item.product_id.nil?
        published = nil
      else
        published = Spree::Product.find(item.product_id).available_on
      end

      if published
        out['publish_state'] = Spree::ProductImportItem::PUBLISH_STATE_PUBLISHED
        out['publish_state_label'] = 'success'
      else
        out['publish_state'] = Spree::ProductImportItem::PUBLISH_STATE_PENDING
        out['publish_state_label'] = 'warning'
      end

      return out
    end

  end
end
