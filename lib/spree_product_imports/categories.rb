module SpreeProductImports
  class Categories

    def self.assign product, item_data
      categories_taxonomy = Spree::Taxonomy.find_by(name: 'Categories')
      categories_base = Spree::Taxon.find_by(name: 'Categories')

      taxon_name = category_taxon_name item_data['type']
      taxon = assign_taxon(taxon_name, categories_base, categories_taxonomy, product)

      if item_data['secondary_category'].present? && !item_data['secondary_category'].nil?
        child_taxon = assign_taxon(item_data['secondary_category'], taxon, categories_taxonomy, product)

        if item_data['tertiary_category'].present? && !item_data['tertiary_category'].nil?
          grandchild_taxon = assign_taxon(item_data['tertiary_category'], child_taxon, categories_taxonomy, product)
        end
      end
    end

    private

    # Get the taxon name corresponding to the value in the "type"
    # column of the spreadsheet.
    def self.category_taxon_name type
      case type
        when 'Wallcovering'
          'Wall Coverings'
        when 'Naturals Fiber Wallcovering'
          'Grasscloth and Naturals'
        when 'Mural'
          'Wall Murals'
        when 'Border'
          'Borders'
        when 'Decal'
          'Wall Decals'
        else
          type
      end
    end

    # Get taxon if it exists, or create it. Append it to the product's taxons.
    def self.assign_taxon name, parent, taxonomy, product
      taxon = Spree::Taxon.find_or_create_by!(name: name, parent: parent, taxonomy: taxonomy)
      parent.children << taxon
      product.taxons << taxon
      product.save!

      taxon
    end

  end

end
