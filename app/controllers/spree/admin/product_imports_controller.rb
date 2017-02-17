module Spree::Admin
  class ProductImportsController < ResourceController

    include ActionController::Live

    require 'csv'
    require 'uri'
    require 'open-uri'
    require 'json'
    require 'net/ftp'

    before_action :set_import_state_labels, only: [:index]
    before_action :destroy_products, only: [:destroy]
    before_action :get_product_import_image_servers, only: [:new, :edit]
    after_action :create_items, only: [:create, :update]

    def index
      respond_with(@collection)
    end

    def import
      response.headers['Content-Type'] = 'text/event-stream'
      Spree::ProductImportItem.where(product_import_id: @product_import.id, state: [Spree::ProductImportItem::STATE_PENDING, Spree::ProductImportItem::STATE_ERROR]).each do |item|
        item = item.create_product
        response.stream.write 'event: update'+$/
        response.stream.write 'data: '+item.to_json+$/+$/
      end

      if Spree::ProductImportItem.where(product_import_id: @product_import.id, state: [Spree::ProductImportItem::STATE_PENDING, Spree::ProductImportItem::STATE_ERROR]).empty?
        @product_import.state = Spree::ProductImport::STATE_COMPLETE
        @product_import.completed_at = DateTime.now
        @product_import.save!
      end

      response.stream.write 'event: update'+$/
      response.stream.write 'data: END:'+@product_import.state+$/+$/

      rescue IOError
        # client disconnected.
      ensure
        response.stream.close
    end

    def delete_import

      id = params[:id]

      begin
        status = 'OK'
        message = ''
        unless Spree::ProductImport.destroy(id)
          status = 'NO'
          message = "Unable to destroy product import id #{id}"
        end
      rescue => e
        status = 'NO'
        message = e.message
      end

      data = { status: status, message: message, import_id: id }.to_json
      response.headers['Content-Type'] = 'text/event-stream'
      response.stream.write 'event: update'+$/
      response.stream.write 'data: '+data+$/+$/

    rescue IOError
      # client disconnected.
    ensure
      response.stream.close
    end

    protected

    def permitted_resource_params
      params.require(:product_import).permit( :name, :product_import_image_server_id, :csv_file )
    end

    private

    def collection
      return @collection if @collection.present?

      params[:q] ||= {}

      params[:q][:s] ||= 'created_at desc'
      @collection = super

      # @search needs to be defined as this is passed to search_form_for
      # This is to include all products and not just deleted products.
      @search = @collection.ransack(params[:q])
      @collection = @search.result.
          page(params[:page]).
          per(params[:per_page] || SpreeProductImports.configuration.admin_product_imports_per_page)
      @collection
    end

    # Set value for import state labels
    def set_import_state_labels
      @product_imports.each do |import|
        case import.state
          when Spree::ProductImport::STATE_PENDING
            import.state_label = 'warning'
          when Spree::ProductImport::STATE_COMPLETE
            import.state_label = 'success'
        end
      end
    end

    # Get contents of the associated csv file
    def set_csv
      @csv = CSV.new(open(@product_import.csv_file.url), headers: true, header_converters: :symbol).map { |record| record.to_h }
      @headers = @csv.first.keys
    end

    # Destroy any imported products when destroying import
    def destroy_products
      Spree::ProductImportItem.where(product_import_id: @product_import.id).each do |item|
        unless item.product_id.nil?
          Spree::Product.destroy(item.product_id)
        end
      end
    end

    def get_product_import_image_servers
      @product_import_image_servers = Spree::ProductImportImageServer.all
    end

    # Create product import items for each row of the csv file. Delete any existing items first.
    def create_items
      Spree::ProductImportItem.delete_all(product_import_id: @product_import.id)
      set_csv
      @csv.each do |csv_item|
        # We get an error trying to convert accented characters if we don't do this
        csv_item.each do |k, v|
          csv_item[k] = v.force_encoding('UTF-8') unless v.nil?
        end
        Spree::ProductImportItem.create!({ product_import_id: @product_import.id, sku: csv_item[:sku], json: csv_item.to_json })
      end
    end

  end
end
