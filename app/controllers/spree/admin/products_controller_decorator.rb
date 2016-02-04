Spree::ProductsController.class_eval do
  after_action :update_import_item, only: :save

  private

  def update_import_item_if_published
    unless @product.available_on.nil?
      import_item = Spree::ProductImportItem.where(product_id: @product.id)
      unless import_item.nil? || import_item.publish_state == Spree::ProductImportItem::PUBLISH_STATE_PUBLISHED
        import_item.publish_state = Spree::ProductImportItem::PUBLISH_STATE_PUBLISHED
        import_item.save
      end
    end
  end

end
