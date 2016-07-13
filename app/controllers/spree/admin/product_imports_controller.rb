module Spree::Admin
  class ProductImportsController < ResourceController

    include ActionController::Live

    require 'csv'
    require 'uri'
    require 'open-uri'
    require 'json'
    require 'net/ftp'
    
    # SAMPLE_VARIANT_PRICE = 5.99
    #
    # MURAL_PANEL_WIDTH_DEFAULT = 52

    # LOG_FILE = Rails.root + 'log/product_import.log'

    before_action :set_import_state_labels, only: [:index]
    before_action :destroy_products, only: [:destroy]
    before_action :get_product_import_image_servers, only: [:new, :edit]
    after_action :create_items, only: [:create, :update]

    def index
      respond_with(@collection)
    end

    def import
      # @log = File.open(LOG_FILE, 'a')

      response.headers['Content-Type'] = 'text/event-stream'
      Spree::ProductImportItem.where(product_import_id: @product_import.id, state: [Spree::ProductImportItem::STATE_PENDING, Spree::ProductImportItem::STATE_ERROR]).each do |item|
        item.create_product
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
          per(params[:per_page] || Spree::ProductImport.admin_product_imports_per_page)
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

    # # Create a product from import data
    # def create_product_from_import_item(item)
    #
    #   begin
    #
    #     item_data = JSON.parse(item.json)
    #     product = Spree::Product.create!(
    #       {
    #         sku: item.sku,
    #         name: item_data['item_name'],
    #         available_on: item_data['publish_status'].to_i == 1 ? Time.now : nil,
    #         expires_on: expires_on(item_data),
    #         description: item_data['brief_description'],
    #         price: item_data['price'],
    #         tax_category: Spree::TaxCategory.find_by_name('Taxable'),
    #         shipping_category: Spree::ShippingCategory.first,
    #         weight: item_data['weight'],
    #         height: item_data['pkg_height'],
    #         width: item_data['pkg_width'],
    #         depth: item_data['pkg_length'],
    #         sale_unit: set_sale_unit(item_data)
    #       }
    #     )
    #
    #     generate_slug product
    #     create_sample_options product
    #     assign_categories product, item_data
    #     assign_branding product, item_data
    #     assign_properties product, item_data
    #     assign_order_information product, item_data
    #     process_images product
    #
    #     item.product_id = product.id
    #     item.state = Spree::ProductImportItem::STATE_IMPORTED
    #     item.state_message = nil
    #     item.imported_at = DateTime.now
    #     item.publish_state = product.available_on.nil? ? Spree::ProductImportItem::PUBLISH_STATE_PENDING : Spree::ProductImportItem::PUBLISH_STATE_PUBLISHED
    #     item.save!
    #
    #   rescue => e
    #
    #     @log.puts([Time.now.to_s, 'Import ID: ' + @product_import.id.to_s,  'SKU: ' + item.sku, e.to_s].join("\t"))
    #     puts ['PRODUCT IMPORT ERROR', 'Import ID: ' + @product_import.id.to_s,  'SKU: ' + item.sku, e.to_s].join("\t")
    #
    #     product.destroy unless product.nil?
    #     item.product_id = nil
    #     item.state = Spree::ProductImportItem::STATE_ERROR
    #     item.state_message = e.to_s
    #     item.imported_at = nil
    #     item.publish_state = Spree::ProductImportItem::PUBLISH_STATE_PENDING
    #     item.save!
    #
    #   end
    #
    #   return item
    #
    # end
    #
    # # Create product options for sample.
    # # Products with samples need sample and actual_item options.
    # def create_sample_options product
    #   option_type = Spree::OptionType.where(name: 'item_or_sample', presentation: 'Product').first_or_create
    #   product.option_types << option_type
    #   create_variant product, 'full'
    #   create_variant product, 'sample'
    # end
    #
    # # Create sample or full variant.
    # def create_variant(product, type)
    #   case type
    #     when 'full'
    #       price = product.price
    #     when 'sample'
    #       price = SAMPLE_VARIANT_PRICE
    #   end
    #
    #   variant = Spree::Variant.create!(
    #     {
    #       product: product,
    #       sku: "#{product.sku}_#{product.id}_#{type}",
    #       price: price,
    #       weight: product.weight,
    #       height: product.height,
    #       width: product.width,
    #       depth: product.depth
    #     }
    #   )
    #
    #   option_type = Spree::OptionType.where(name: 'item_or_sample', presentation: 'Product').first_or_create
    #   case type
    #     when 'full'
    #       variant.option_values << Spree::OptionValue.where({presentation: 'Full', name: 'actual_item', option_type: option_type}).first_or_create
    #     when 'sample'
    #       variant.option_values << Spree::OptionValue.where(name: 'Sample', presentation: 'Sample', option_type: option_type).first_or_create
    #   end
    #   variant.save!
    # end
    #
    # # If expiration date is set, format it for insertion into database.
    # def expires_on(item_data)
    #   unless item_data['expiration_date'].nil?
    #     Date.strptime(item_data['expiration_date'], '%m/%d/%Y').to_time
    #   end
    # end
    #
    # # Set sale unit, if provided
    # def set_sale_unit(item_data)
    #   unless item_data['sold_by'].nil?
    #     return Spree::SaleUnit.find_or_create_by(name: item_data['sold_by'])
    #   end
    # end
    #
    # # Generate product slug
    # def generate_slug(product)
    #   product.slug = product.name.parameterize + '-pr-' + product.id.to_s
    #   product.save!
    # end
    #
    # # Attach category taxons to the product
    # def assign_categories(product, item_data)
    #   categories_taxonomy = Spree::Taxonomy.find_by(name: 'Categories')
    #   categories_base = Spree::Taxon.find_by_name('Categories')
    #
    #   # Find category taxon by name. If it doesn't exist, create it.
    #   # Append it to the item's taxons.
    #   taxon_name = get_category_taxon_name(item_data['type'])
    #   taxon = Spree::Taxon.where(name: taxon_name, taxonomy_id: categories_base.taxonomy_id).first_or_create!
    #   categories_base.children << taxon
    #   product.taxons << taxon
    #
    #   # # Now get the secondary category taxon (if one is provided), or create it if it doesn't exist
    #   # if item_data['secondary_category'].present? && !item_data['secondary_category'].nil?
    #   #   child_taxon = Spree::Taxon.where(name: item_data['secondary_category'], parent: taxon, taxonomy: categories_taxonomy).first_or_create!
    #   #   taxon.children << child_taxon
    #   #   product.taxons << child_taxon
    #   # end
    #
    #   product.save!
    # end
    #
    # # Get the taxon name corresponding to the value in the "type"
    # # column of the spreadsheet.
    # def get_category_taxon_name(type_from_spreadsheet)
    #   case type_from_spreadsheet
    #     when 'Wallcovering'
    #       taxon_name = 'Wall Coverings'
    #     when 'Naturals Fiber Wallcovering'
    #       taxon_name = 'Grasscloth and Naturals'
    #     when 'Mural'
    #       taxon_name = 'Wall Murals'
    #     when 'Border'
    #       taxon_name = 'Borders'
    #     when 'Decal'
    #       taxon_name = 'Wall Decals'
    #     else
    #       taxon_name = type_from_spreadsheet
    #   end
    #   return taxon_name
    # end
    #
    # # Assign a brand to the product.
    # def assign_branding(product, item_data)
    #   # First, get base brand taxon.
    #   categories_taxonomy = Spree::Taxonomy.find_or_create_by(name: 'Categories')
    #   brands_base = Spree::Taxon.where(name: 'Brands', taxonomy: categories_taxonomy).first_or_create
    #
    #   # Find brand taxon by name, or create it. Append it to the item's taxons.
    #   taxon = Spree::Taxon.where(name: item_data['brand'], taxonomy: categories_taxonomy).first_or_create
    #   brands_base.children << taxon
    #   product.taxons << taxon
    #
    #   # Now get the secondary brand (collection) under the main brand, or create it if it doesn't exist
    #   child_taxon = Spree::Taxon.where(name: item_data['main_category'], parent: taxon, taxonomy: categories_taxonomy).first_or_create
    #   taxon.children << child_taxon
    #   product.taxons << child_taxon
    #
    #   product.save!
    # end
    #
    # # Assign properties.
    # def assign_properties(product, item_data)
    #
    #   unless item_data['roll_width'].nil?
    #     product.set_property('roll width', item_data['roll_width'])
    #   end
    #
    #   unless item_data['roll_length_yds'].nil?
    #     product.set_property('roll length', item_data['roll_length_yds'])
    #   end
    #
    #   unless item_data['repeat_height'].nil? || item_data['repeat_height'].to_f.zero?
    #     product.set_property('repeat height', item_data['repeat_height'])
    #   else
    #     product.set_property('repeat height', 'None')
    #   end
    #
    #   unless item_data['repeat_width'].nil? || item_data['repeat_width'].to_f.zero?
    #     product.set_property('repeat width', item_data['repeat_width'])
    #   end
    #
    #   unless item_data['match_type'].nil?
    #     product.set_property('repeat match type', item_data['match_type'])
    #   end
    #
    #   unless item_data['washability'].nil?
    #     product.set_property('washability', item_data['washability'])
    #   end
    #
    #   unless item_data['removability'].nil?
    #     product.set_property('removability', item_data['removability'])
    #   end
    #
    #   unless item_data['prepasted'].nil?
    #     product.set_property('pre-pasted', item_data['prepasted'])
    #   end
    #
    #   unless item_data['margin_trim'].nil?
    #     product.set_property('margin trim', item_data['margin_trim'])
    #   end
    #
    #   unless item_data['sold_by'].nil?
    #     product.set_property('sold by', item_data['sold_by'])
    #   end
    #
    #   unless item_data['count_by'].nil?
    #     product.set_property('count by', item_data['count_by'])
    #   end
    #
    #   unless item_data['minimum_qnty'].nil?
    #     product.set_property('minimum quantity', item_data['minimum_qnty'])
    #   end
    #
    #   unless item_data['mural_width'].nil?
    #     product.set_property('mural width', item_data['mural_width'])
    #   end
    #
    #   unless item_data['mural_height'].nil?
    #     product.set_property('mural height', item_data['mural_height'])
    #   end
    #
    #   unless item_data['panel_count'].nil?
    #     product.set_property('panel count', item_data['panel_count'])
    #   else
    #     # If we have a mural width without an explicit panel count, calculate it
    #     unless item_data['mural_width'].nil?
    #       product.set_property('panel count', (item_data['mural_width'].to_f / MURAL_PANEL_WIDTH_DEFAULT).ceil)
    #     end
    #   end
    #
    #   unless item_data['printtoorder'].nil?
    #     product.set_property('print-to-order', 'Yes')
    #   end
    #
    # end
    #
    # # Assign "Ordering Information" items.
    # def assign_order_information(product, item_data)
    #
    #   product.order_info_items << Spree::OrderInfoItem.where(name: 'Please confirm availability -- 3-8 week lead time').take
    #
    #   case item_data['type']
    #     when 'Wallpaper'
    #       product.order_info_items << Spree::OrderInfoItem.where(name: 'Colors may vary - please order sample').take
    #
    #       if item_data['default_qnty'].to_i == 2
    #         product.order_info_items << Spree::OrderInfoItem.where(name: 'Double roll').take
    #       end
    #   end
    #
    #   unless item_data['printtoorder'].nil?
    #     product.order_info_items << Spree::OrderInfoItem.find_by({ name: 'Unprinted margins' })
    #     product.order_info_items << Spree::OrderInfoItem.find_by({ name: 'Customization available' })
    #   end
    # end
    #
    # # Get associated product images and attach to product.
    # def process_images(product)
    #   product_import_image_server = Spree::ProductImportImageServer.find(@product_import.product_import_image_server_id)
    #   case product_import_image_server.protocol
    #     when 'ftp'
    #       images_by_ftp product, product_import_image_server
    #     when 'http'
    #       images_by_http product, product_import_image_server
    #     else
    #       raise 'Unknown protocol.'
    #   end
    # end
    #
    # # Get images from FTP server.
    # def images_by_ftp product, image_server
    #
    #   ftp = Net::FTP.new(image_server.url)
    #   ftp.passive = true
    #   ftp.login image_server.username, image_server.password
    #
    #   image_count = 0
    #
    #   @product_import.product_import_image_locations.each do |location|
    #     begin
    #
    #       ftp.chdir(location.path)
    #       filename = filename_from_sku product.sku, location.filename_pattern
    #
    #       img_data = ftp.getbinaryfile(filename, nil)
    #       unless img_data.nil?
    #         img = File.new(filename, 'wb')
    #         img.write(img_data)
    #         Spree::Image.create attachment: img, viewable: product.master
    #         File.delete(img.path)
    #         image_count += 1
    #       end
    #
    #         # # Can't get this to work -- Paperclip throws an error: "Paperclip::Errors::NotIdentifiedByImageMagickError"
    #         # img_data = ftp.getbinaryfile(filename, nil)
    #         # data_uri = 'data:image/jpeg;base64,'+img_data
    #         # img = Paperclip.io_adapters.for(data_uri)
    #         # img.original_filename = filename
    #         # img.content_type = 'image/jpeg'
    #         # Spree::Image.create attachment: img, viewable: product.master
    #
    #     rescue => e
    #
    #       @log.puts([Time.now.to_s, 'Import ID: ' + @product_import.id.to_s, 'SKU: ' + product.sku, e.to_s].join("\t"))
    #       puts([Time.now.to_s, 'IMAGE CREATION ERROR', 'Import ID: ' + @product_import.id.to_s, 'SKU: ' + product.sku, e.to_s].join("\t"))
    #
    #       # Do nothing here -- not all products have every type of image.
    #       next
    #
    #     end
    #
    #   end
    #
    #   # Raise an exception if no images were successfully processed.
    #   unless image_count > 0
    #     raise 'No images created'
    #   end
    # end
    #
    # # Get images from a web server.
    # def images_by_http(product, image_server)
    #
    #   image_count = 0
    #
    #   @product_import.product_import_image_locations.each do |location|
    #     begin
    #
    #       filename = filename_from_sku product.sku, location.filename_pattern
    #       image_url = image_server.url + '/' + location.path + '/' + filename
    #
    #       img = open(URI.encode(image_url))
    #       status = img.status[0]
    #
    #       if status.to_i == 200
    #         Spree::Image.create attachment: img, viewable: product.master
    #         image_count += 1
    #       end
    #
    #     rescue => e
    #
    #       @log.puts([Time.now.to_s, 'Import ID: ' + @product_import.id.to_s, 'SKU: ' + product.sku, e.to_s].join("\t"))
    #       puts([Time.now.to_s, 'IMAGE CREATION ERROR', 'Import ID: ' + @product_import.id.to_s, 'SKU: ' + product.sku, e.to_s].join("\t"))
    #
    #       # Do nothing here -- not all products have every type of image.
    #       next
    #
    #     end
    #
    #   end
    #
    #   # Raise an exception if no images were successfully processed.
    #   unless image_count > 0
    #     raise 'No images created'
    #   end
    # end
    #
    # # Use pattern to generate filename from SKU.
    # def filename_from_sku(sku, filename_pattern)
    #   re = /^<SKU( replace="([^"]*)")?>/
    #   replacements = re.match(filename_pattern)[2]
    #
    #   unless replacements.nil?
    #     replacements.split(';').each do |pair|
    #       if pair.start_with? ','
    #         raise 'String to find in SKU cannot be empty'
    #       end
    #       find, replace = pair.split(',', -1) # Enables replacement of a string with an empty string (remove characters from SKU)
    #       sku = sku.sub(find, replace)
    #     end
    #   end
    #
    #   return filename_pattern.sub(re, sku)
    # end
  end
end
