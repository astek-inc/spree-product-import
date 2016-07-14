module Spree
  class ProductImportItem < Spree::Base

    require 'uri'
    require 'open-uri'
    require 'json'
    require 'net/ftp'

    STATE_PENDING = 'pending'
    STATE_IMPORTED = 'imported'
    STATE_ERROR = 'error'

    PUBLISH_STATE_PENDING = 'pending'
    PUBLISH_STATE_PUBLISHED = 'published'

    SAMPLE_VARIANT_PRICE = 5.99
    MURAL_PANEL_WIDTH_DEFAULT = 52

    belongs_to :product_import
    belongs_to :product

    attr_accessor :state_label

    def create_product
      begin
        @item_data = JSON.parse(self.json)
        @product = Spree::Product.create!({
          sku: self.sku,
          name: @item_data['item_name'],
          available_on: @item_data['publish_status'].to_i == 1 ? Time.now : nil,
          expires_on: expires_on,
          description: @item_data['brief_description'],
          price: @item_data['price'],
          tax_category: Spree::TaxCategory.find_by_name('Taxable'),
          shipping_category: Spree::ShippingCategory.first,
          weight: @item_data['weight'],
          height: @item_data['pkg_height'],
          width: @item_data['pkg_width'],
          depth: @item_data['pkg_length'],
          sale_unit: set_sale_unit,
          country_of_origin: country_of_origin
        })

        generate_slug
        create_sample_options
        assign_categories
        assign_branding
        assign_properties
        assign_order_information
        process_images

        self.product_id = @product.id
        self.state = Spree::ProductImportItem::STATE_IMPORTED
        self.state_message = nil
        self.imported_at = DateTime.now
        self.publish_state = @product.available_on.nil? ? PUBLISH_STATE_PENDING : PUBLISH_STATE_PUBLISHED
        self.save!

      rescue => e
        puts ['PRODUCT IMPORT ERROR', 'Import ID: ' + self.product_import.id.to_s,  'SKU: ' + self.sku, e.to_s].join("\t")

        @product.destroy unless @product.nil?

        self.product_id = nil
        self.state = STATE_ERROR
        self.state_message = e.to_s
        self.imported_at = nil
        self.publish_state = PUBLISH_STATE_PENDING
        self.save!
      end

      self
    end

    # Create product options for sample.
    # Products with samples need sample and actual_item options.
    def create_sample_options
      option_type = Spree::OptionType.where(name: 'item_or_sample', presentation: 'Product').first_or_create
      @product.option_types << option_type
      create_variant 'full'
      create_variant 'sample'
    end

    # Create sample or full variant.
    def create_variant(type)
      case type
        when 'full'
          price = @product.price
        when 'sample'
          price = SAMPLE_VARIANT_PRICE
      end

      variant = Spree::Variant.create!({
        product: @product,
        sku: "#{@product.sku}_#{@product.id}_#{type}",
        price: price,
        weight: @product.weight,
        height: @product.height,
        width: @product.width,
        depth: @product.depth
      })

      option_type = Spree::OptionType.where(name: 'item_or_sample', presentation: 'Product').first_or_create
      case type
        when 'full'
          variant.option_values << Spree::OptionValue.where({presentation: 'Full', name: 'actual_item', option_type: option_type}).first_or_create
        when 'sample'
          variant.option_values << Spree::OptionValue.where(name: 'Sample', presentation: 'Sample', option_type: option_type).first_or_create
      end

      variant.save!
    end

    # If expiration date is set, format it for insertion into database.
    def expires_on
      unless @item_data['expiration_date'].nil?
        Date.strptime(@item_data['expiration_date'], '%m/%d/%Y').to_time
      end
    end

    def set_sale_unit
      unless @item_data['sold_by'].nil?
        Spree::SaleUnit.find_or_create_by(name: @item_data['sold_by'])
      end
    end

    def generate_slug
      @product.slug = @product.name.parameterize + '-pr-' + @product.id.to_s
      @product.save!
    end

    def assign_categories
      categories_taxonomy = Spree::Taxonomy.find_by(name: 'Categories')
      categories_base = Spree::Taxon.find_by_name('Categories')

      # Find category taxon by name. If it doesn't exist, create it.
      # Append it to the item's taxons.
      taxon_name = get_category_taxon_name(@item_data['type'])
      taxon = Spree::Taxon.where(name: taxon_name, taxonomy_id: categories_base.taxonomy_id).first_or_create!
      categories_base.children << taxon
      @product.taxons << taxon

      # # Now get the secondary category taxon (if one is provided), or create it if it doesn't exist
      # if @item_data['secondary_category'].present? && !@item_data['secondary_category'].nil?
      #   child_taxon = Spree::Taxon.where(name: @item_data['secondary_category'], parent: taxon, taxonomy: categories_taxonomy).first_or_create!
      #   taxon.children << child_taxon
      #   @product.taxons << child_taxon
      # end

      @product.save!
    end

    # Get the taxon name corresponding to the value in the "type"
    # column of the spreadsheet.
    def get_category_taxon_name(type)
      case type
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
          taxon_name = type
      end

      taxon_name
    end

    def assign_branding
      # First, get base brand taxon.
      categories_taxonomy = Spree::Taxonomy.find_or_create_by(name: 'Categories')
      brands_base = Spree::Taxon.where(name: 'Brands', taxonomy: categories_taxonomy).first_or_create

      # Find brand taxon by name, or create it. Append it to the item's taxons.
      taxon = Spree::Taxon.where(name: @item_data['brand'], taxonomy: categories_taxonomy).first_or_create
      brands_base.children << taxon
      @product.taxons << taxon

      # Now get the secondary brand (collection) under the main brand, or create it if it doesn't exist
      child_taxon = Spree::Taxon.where(name: @item_data['main_category'], parent: taxon, taxonomy: categories_taxonomy).first_or_create
      taxon.children << child_taxon
      @product.taxons << child_taxon

      @product.save!
    end

    def assign_properties

      unless @item_data['roll_width'].nil?
        @product.set_property('roll width', @item_data['roll_width'])
      end

      unless @item_data['roll_length_yds'].nil?
        @product.set_property('roll length', @item_data['roll_length_yds'])
      end

      unless @item_data['repeat_height'].nil? || @item_data['repeat_height'].to_f.zero?
        @product.set_property('repeat height', @item_data['repeat_height'])
      else
        @product.set_property('repeat height', 'None')
      end

      unless @item_data['repeat_width'].nil? || @item_data['repeat_width'].to_f.zero?
        @product.set_property('repeat width', @item_data['repeat_width'])
      end

      unless @item_data['match_type'].nil?
        @product.set_property('repeat match type', @item_data['match_type'])
      end

      unless @item_data['washability'].nil?
        @product.set_property('washability', @item_data['washability'])
      end

      unless @item_data['removability'].nil?
        @product.set_property('removability', @item_data['removability'])
      end

      unless @item_data['prepasted'].nil?
        @product.set_property('pre-pasted', @item_data['prepasted'])
      end

      unless @item_data['margin_trim'].nil?
        @product.set_property('margin trim', @item_data['margin_trim'])
      end

      unless @item_data['sold_by'].nil?
        @product.set_property('sold by', @item_data['sold_by'])
      end

      unless @item_data['count_by'].nil?
        @product.set_property('count by', @item_data['count_by'])
      end

      unless @item_data['minimum_qnty'].nil?
        @product.set_property('minimum quantity', @item_data['minimum_qnty'])
      end

      unless @item_data['mural_width'].nil?
        @product.set_property('mural width', @item_data['mural_width'])
      end

      unless @item_data['mural_height'].nil?
        @product.set_property('mural height', @item_data['mural_height'])
      end

      unless @item_data['panel_count'].nil?
        @product.set_property('panel count', @item_data['panel_count'])
      else
        # If we have a mural width without an explicit panel count, calculate it
        unless @item_data['mural_width'].nil?
          @product.set_property('panel count', (@item_data['mural_width'].to_f / MURAL_PANEL_WIDTH_DEFAULT).ceil)
        end
      end

      unless @item_data['printtoorder'].nil?
        @product.set_property('print-to-order', 'Yes')
      end

    end

    # Assign items for "Ordering Information" box on product page
    def assign_order_information
      @product.order_info_items << Spree::OrderInfoItem.where(name: 'Please confirm availability -- 3-8 week lead time').take

      case @item_data['type']
        when 'Wallpaper'
          @product.order_info_items << Spree::OrderInfoItem.where(name: 'Colors may vary - please order sample').take

          if @item_data['default_qnty'].to_i == 2
            @product.order_info_items << Spree::OrderInfoItem.where(name: 'Double roll').take
          end
      end

      unless @item_data['printtoorder'].nil?
        @product.order_info_items << Spree::OrderInfoItem.find_by({ name: 'Unprinted margins' })
        @product.order_info_items << Spree::OrderInfoItem.find_by({ name: 'Customization available' })
      end
    end

    def country_of_origin
      iso = @item_data['country_of_origin'].nil? ? 'US' : @item_data['country_of_origin']
      begin
        Spree::Country.find_by(iso: iso).id
      rescue => e
        raise "Cannot find country by code #{iso}: #{e}"
      end
    end

    # Get associated product images and attach to product
    def process_images
      @image_server = Spree::ProductImportImageServer.find(self.product_import.product_import_image_server_id)
      case @image_server.protocol
        when 'ftp'
          images_by_ftp
        when 'http'
          images_by_http
        else
          raise 'Unknown protocol.'
      end
    end

    # Get images from an FTP server
    def images_by_ftp
      ftp = Net::FTP.new(@image_server.url)
      ftp.passive = true
      ftp.login @image_server.username, @image_server.password

      image_count = 0
      self.product_import.product_import_image_locations.each do |location|
        begin
          ftp.chdir(location.path)
          filename = filename_from_sku @product.sku, location.filename_pattern

          img_data = ftp.getbinaryfile(filename, nil)
          unless img_data.nil?
            img = File.new(filename, 'wb')
            img.write(img_data)
            Spree::Image.create attachment: img, viewable: @product.master
            File.delete(img.path)
            image_count += 1
          end

          # # Can't get this to work -- Paperclip throws an error: "Paperclip::Errors::NotIdentifiedByImageMagickError"
          # img_data = ftp.getbinaryfile(filename, nil)
          # data_uri = 'data:image/jpeg;base64,'+img_data
          # img = Paperclip.io_adapters.for(data_uri)
          # img.original_filename = filename
          # img.content_type = 'image/jpeg'
          # Spree::Image.create attachment: img, viewable: @product.master

        rescue => e
          puts([Time.now.to_s, 'IMAGE CREATION ERROR', 'Import ID: ' + self.product_import.id.to_s, 'SKU: ' + @product.sku, e.to_s].join("\t"))
          # Do nothing here -- not all products have every type of image.
          next
        end
      end

      # Raise an exception if no images were successfully processed.
      unless image_count > 0
        raise 'No images created'
      end
    end

    # Get images from a web server
    def images_by_http
      image_count = 0
      self.product_import.product_import_image_locations.each do |location|
        begin
          filename = filename_from_sku @product.sku, location.filename_pattern
          image_url = @image_server.url + '/' + location.path + '/' + filename

          img = open(URI.encode(image_url))
          status = img.status[0]

          if status.to_i == 200
            Spree::Image.create attachment: img, viewable: @product.master
            image_count += 1
          end
        rescue => e
          puts([Time.now.to_s, 'IMAGE CREATION ERROR', 'Import ID: ' + self.product_import.id.to_s, 'SKU: ' + @product.sku, e.to_s].join("\t"))
          # Do nothing here -- not all @products have every type of image.
          next
        end
      end

      # Raise an exception if no images were successfully processed.
      unless image_count > 0
        raise 'No images created'
      end
    end

    # Use pattern to generate filename from SKU.
    def filename_from_sku(sku, filename_pattern)
      re = /^<SKU( replace="([^"]*)")?>/
      replacements = re.match(filename_pattern)[2]

      unless replacements.nil?
        replacements.split(';').each do |pair|
          if pair.start_with? ','
            raise 'String to find in SKU cannot be empty'
          end
          find, replace = pair.split(',', -1) # Enables replacement of a string with an empty string (remove characters from SKU)
          sku = sku.sub(find, replace)
        end
      end

      filename_pattern.sub(re, sku)
    end
  end

end
