module Spree::Admin
  class ProductImportsController < ResourceController

    include ActionController::Live

    IMPORT_ITEM_STATE_PENDING = 'pending'
    IMPORT_ITEM_STATE_IMPORTED = 'imported'

    IMPORT_ITEM_PUBLISH_STATE_PENDING = 'pending'
    IMPORT_ITEM_PUBLISH_STATE_PUBLISHED = 'published'

    IMPORT_STATE_PENDING = 'pending'
    IMPORT_STATE_COMPLETE = 'complete'

    IMAGE_URL_BASE = 'https://s3-us-west-2.amazonaws.com/dyw-product-upload/images'

    SAMPLE_VARIANT_PRICE = 5.99

    require 'csv'
    require 'open-uri'
    require 'json'

    before_action :set_import_state_labels, only: [:index]
    # before_action :set_csv, only: [:show, :import]
    before_action :set_item_display_data, only: [:show]
    before_action :destroy_products, only: [:destroy]
    after_action :create_items, only: [:create]

    def import
      response.headers['Content-Type'] = 'text/event-stream'
      Spree::ProductImportItem.where(product_import_id: @product_import.id, state: IMPORT_ITEM_STATE_PENDING).each do |item|
        item = create_product_from_import_item(item)
        response.stream.write 'event: update'+$/
        response.stream.write 'data: '+item.to_json+$/+$/
      end

      if Spree::ProductImportItem.where(product_import_id: @product_import.id, state: IMPORT_ITEM_STATE_PENDING).empty?
        @product_import.state = IMPORT_STATE_COMPLETE
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

    private

    def permitted_resource_params
      params.require(:product_import).permit( :name, :csv_file )
    end

    # Set value for import state labels
    def set_import_state_labels
      @product_imports.each do |import|
        case import.state
          when IMPORT_STATE_PENDING
            import.state_label = 'warning'
          when IMPORT_STATE_COMPLETE
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

    # Create product import items for each row of the csv file
    def create_items
      set_csv
      @csv.each do |csv_item|
        Spree::ProductImportItem.create!(
          {
            product_import_id: @product_import.id,
            sku: csv_item[:sku],
            json: csv_item.to_json
          }
        )
      end
    end

    # Extract data to a hash for simple output
    def set_item_display_data
      @item_display_data = @product_import.product_import_items.map { |item| set_display_data item }
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
        when IMPORT_ITEM_STATE_PENDING
          out['state_label'] = 'warning'
        when IMPORT_ITEM_STATE_IMPORTED
          out['state_label'] = 'success'
      end

      if item.product_id.nil?
        published = nil
      else
        published = Spree::Product.find(item.product_id).available_on
      end

      if published
        out['publish_state'] = IMPORT_ITEM_PUBLISH_STATE_PUBLISHED
        out['publish_state_label'] = 'success'
      else
        out['publish_state'] = IMPORT_ITEM_PUBLISH_STATE_PENDING
        out['publish_state_label'] = 'warning'
      end

      return out
    end

    # Create a product from import data
    def create_product_from_import_item(item)
      item_data = JSON.parse(item.json)
      product = Spree::Product.create(
        {
          sku: item.sku,
          name: item_data['item_name'],
          available_on: item_data['publish_status'].to_i == 1 ? Time.now : nil,
          description: item_data['brief_description'],
          price: item_data['price'],
          tax_category: Spree::TaxCategory.find_by_name('Taxable'),
          shipping_category: Spree::ShippingCategory.first,
          weight: item_data['weight'],
          height: item_data['pkg_height'],
          width: item_data['pkg_width'],
          depth: item_data['pkg_length']
        }
      )

      generate_slug product
      create_sample_options product
      assign_categories product, item_data
      assign_branding product, item_data
      assign_properties product, item_data
      assign_order_information product, item_data
      process_image product

      item.product_id = product.id
      item.state = IMPORT_ITEM_STATE_IMPORTED
      item.imported_at = DateTime.now
      item.publish_state = product.available_on.nil? ? IMPORT_ITEM_PUBLISH_STATE_PENDING : IMPORT_ITEM_PUBLISH_STATE_PUBLISHED
      item.save!
      return item
    end

    # Create product options for sample.
    # Products with samples need sample and actual_item options.
    def create_sample_options product
      option_type = Spree::OptionType.where(name: 'item_or_sample', presentation: 'Product').first_or_create
      product.option_types << option_type
      create_variant product, 'full'
      create_variant product, 'sample'
    end

    # Create sample or full variant.
    def create_variant(product, type)
      case type
        when 'full'
          price = product.price
        when 'sample'
          price = SAMPLE_VARIANT_PRICE
      end

      variant = Spree::Variant.create!(
        {
          product: product,
          sku: "#{product.sku}_#{product.id}_#{type}",
          price: price,
          weight: product.weight,
          height: product.height,
          width: product.width,
          depth: product.depth
        }
      )

      option_type = Spree::OptionType.where(name: 'item_or_sample', presentation: 'Product').first_or_create
      case type
        when 'full'
          variant.option_values << Spree::OptionValue.where({presentation: 'Full', name: 'actual_item', option_type: option_type}).first_or_create
        when 'sample'
          variant.option_values << Spree::OptionValue.where(name: 'Sample', presentation: 'Sample', option_type: option_type).first_or_create
      end
      variant.save!
    end

    # Generate product slug
    def generate_slug(product)
      product.slug = product.name.parameterize + '-pr-' + product.id.to_s
      product.save!
    end

    # Attach category taxons to the product
    def assign_categories(product, item_data)
      categories_taxonomy = Spree::Taxonomy.find_by(name: 'Categories')
      categories_base = Spree::Taxon.find_by_name('Categories')

      # Find category taxon by name. If it doesn't exist, create it.
      # Append it to the item's taxons.
      taxon_name = get_category_taxon_name(item_data['type'])
      taxon = Spree::Taxon.where(name: taxon_name, taxonomy_id: categories_base.taxonomy_id).first_or_create!
      categories_base.children << taxon
      product.taxons << taxon

      # # Now get the secondary category taxon (if one is provided), or create it if it doesn't exist
      # if item_data['secondary_category'].present? && !item_data['secondary_category'].nil?
      #   child_taxon = Spree::Taxon.where(name: item_data['secondary_category'], parent: taxon, taxonomy: categories_taxonomy).first_or_create!
      #   taxon.children << child_taxon
      #   product.taxons << child_taxon
      # end

      product.save!
    end

    # Get the taxon name corresponding to the value in the "type"
    # column of the spreadsheet.
    def get_category_taxon_name(type_from_spreadsheet)
      case type_from_spreadsheet
        when 'Wallcovering'
          taxon_name = 'Wall Coverings'
        when 'Naturals Fiber Wallcovering'
          taxon_name = 'Grasscloth and Naturals'
        when 'Mural'
          taxon_name = 'Wall Murals'
        when 'Border'
          taxon_name = 'Borders'
        when 'Decal'
          taxon_name = 'Wall Decals'
        else
          taxon_name = type_from_spreadsheet
      end
      return taxon_name
    end

    # Assign a brand to the product.
    def assign_branding(product, item_data)
      # First, get base brand taxon (or create it). Then add the item's brand.
      brands_taxonomy = Spree::Taxonomy.find_or_create_by(name: 'Brands')
      brands_base = Spree::Taxon.find_by_name('Brands')

      # Find brand taxon by name, or create it. Append it to the item's taxons.
      taxon = Spree::Taxon.where(name: item_data['brand'], taxonomy_id: brands_base.taxonomy_id).first_or_create
      brands_base.children << taxon
      product.taxons << taxon

      # Now get the secondary brand (collection) under the main brand, or create it if it doesn't exist
      child_taxon = Spree::Taxon.where(name: item_data['main_category'], parent: taxon, taxonomy: brands_taxonomy).first_or_create
      taxon.children << child_taxon
      product.taxons << child_taxon

      product.save!
    end

    # Assign properties.
    def assign_properties(product, item_data)

      unless item_data['roll_width'].nil?
        product.set_property('roll width', item_data['roll_width'])
      end

      unless item_data['roll_length_yds'].nil?
        product.set_property('roll length', item_data['roll_length_yds'])
      end

      unless item_data['repeat_height'].nil? || item_data['repeat_height'].to_f.zero?
        product.set_property('repeat height', item_data['repeat_height'])
      else
        product.set_property('repeat height', 'None')
      end

      # unless item_data['repeat_width'].nil? || item_data['repeat_width'].to_f.zero?
      #   product.set_property('repeat width', item_data['repeat_width'])
      # end

      unless item_data['match_type'].nil?
        product.set_property('repeat match type', item_data['match_type'])
      end

      unless item_data['washability'].nil?
        product.set_property('washability', item_data['washability'])
      end

      unless item_data['removability'].nil?
        product.set_property('removability', item_data['removability'])
      end

      unless item_data['prepasted'].nil?
        product.set_property('pre-pasted', item_data['prepasted'])
      end

    end

    # Assign "Ordering Information" items.
    def assign_order_information(product, item_data)
      case item_data['type']
        when 'Wallpaper'
          order_info_item = Spree::OrderInfoItem.where(name: 'Colors may vary - please order sample')
      end
      product.order_info_items << order_info_item
    end

    # Process associated product image.
    def process_image(product)
      # url_base = Spree::ProductImport.image_url_base

      %w[jpg jpeg png gif].each do |extension|
        image_url = IMAGE_URL_BASE + '/' + product.sku + '.' + extension
        img = open(URI.encode(image_url))
        status = img.status[0]

        if status.to_i == 200
          Spree::Image.create attachment: img, viewable: product.master
          break
        end
      end
    end

  end
end
