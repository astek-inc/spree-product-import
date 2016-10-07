module SpreeProductImports
  class Branding

    def self.assign product, item_data
      unless item_data['brand'].nil?

        # Get base brand taxon.
        categories_taxonomy = Spree::Taxonomy.find_or_create_by(name: 'Categories')
        brands_base = Spree::Taxon.find_or_create_by!(name: 'Brands', taxonomy: categories_taxonomy)

        # Find brand taxon by name, or create it. Append it to the item's taxons.
        taxon = Spree::Taxon.find_or_create_by!(name: item_data['brand'], parent: brands_base, taxonomy: categories_taxonomy)
        brands_base.children << taxon
        product.taxons << taxon

        # Now get the secondary brand (collection) under the main brand, or create it if it doesn't exist
        if item_data['collection'].present? && !item_data['collection'].nil?
          child_taxon = Spree::Taxon.find_or_create_by!(name: item_data['collection'], parent: taxon, taxonomy: categories_taxonomy)
          taxon.children << child_taxon
          product.taxons << child_taxon
        end

        product.save!

      end
    end

  end
end
