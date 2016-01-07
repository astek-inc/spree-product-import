module Spree::Admin
  class ProductImportsController < ResourceController

    require 'csv'
    require 'open-uri'
    require 'json'

    before_action :set_import_state_labels, only: [:index]
    # before_action :set_csv, only: [:show, :import]
    before_action :set_item_display_data, only: [:show]
    after_action :create_items, only: [:create]

    def import
      @product_import_items = Spree::ProductImportItem.where(product_import_id: @product_import.id, state: 'pending').map { |item| create_product_from_import_item item }
      if Spree::ProductImportItem.where(product_import_id: @product_import.id, state: 'pending').empty?
        @product_import.state = 'complete'
        @product_import.completed_at = DateTime.now
        @product_import.save!
      end
      respond_to :js
    end

    private

    def set_import_state_labels
      @product_imports.each do |import|
        case import.state
          when 'pending'
            import.state_label = 'warning'
          when 'complete'
            import.state_label = 'success'
        end
      end
    end

    # Get contents of the associated csv file
    def set_csv
      @csv = CSV.new(open(@product_import.csv_file.url), headers: true, header_converters: :symbol).map { |record| record.to_h }
      @headers = @csv.first.keys
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
          'primary_category' => data['type']
      }
      case item.state
        when 'pending'
          out['state_label'] = 'warning'
        when 'imported'
          out['state_label'] = 'success'
      end
      return out
    end

    def permitted_resource_params
      params.require(:product_import).permit( :name, :csv_file )
    end

    # Create a product from import data
    def create_product_from_import_item(item)
      item_data = JSON.parse(item.json)
      product = Spree::Product.create(
          {
            sku: item.sku,
            name: item_data['item_name'],
            available_on: Time.now,
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
      assign_category product, item_data
      assign_branding product, item_data
      # # assign_properties product, item
      # # upload_images product, item

      item.product_id = product.id
      item.state = 'imported'
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
          price = 5.99
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

    # Attach a primary category to the product
    def assign_category(product, item_data)
      categories_base = Spree::Taxon.find_by_name('Categories')

      # Find category taxon by name. If it doesn't exist, create it.
      # Append it to the item's taxons.
      taxon = Spree::Taxon.where(name: item_data['type'], taxonomy_id: categories_base.taxonomy_id).first
      if taxon.nil?
        taxon = Spree::Taxon.create(name: item_data['type'], taxonomy_id: categories_base.taxonomy_id)
        categories_base.children << taxon
      end

      product.taxons << taxon
      product.save!
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

      # if item_data['washability'] == 'Washable'
      #   property = Spree::Property.find_by_name('washable')
      #   Spree::ProductProperty.create(property: property, item: product, value: 'Washable')
      # end
      #
      # if item_data['removability'] == 'Strippable'
      #   property = Spree::Property.find_by_name('strippable')
      #   Spree::ProductProperty.create(property: property, item: product, value: 'Strippable')
      # end
      #
      # if item_data['pre-pasted'] == 'Yes'
      #   property = Spree::Property.find_by_name('pre-pasted')
      #   Spree::ProductProperty.create(property: property, item: product, value: 'Pre Pasted')
      # end

    end

    def upload_images(product, item_data)
      # Upload images
      item['images'].each_with_index do |image, i|
        if /png|jpeg|jpg|gif/i =~ image['url']

          begin
            @img = open(URI.encode(image['url']))
            status = @img.status[0]
          rescue OpenURI::HTTPError => error
            # @errors << "product# #{p.id} error: #{error.io.status[0]}"
          end

          if status.to_i == 200
            begin
              Spree::Image.create attachment: @img, viewable: p.master
            rescue Paperclip::Error => error
              # @errors << "product# #{p.id} error: #{error}"
              #
              # # The main image failed so delete the product.
              # if i == 0
              #   @errors << "Failed on main image, Product# #{p.id} destroyed."
              #   return p.destroy
              # end

            end
          end
        end
      end
    end

  end
end
