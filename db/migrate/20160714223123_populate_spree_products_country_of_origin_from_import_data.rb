class PopulateSpreeProductsCountryOfOriginFromImportData < ActiveRecord::Migration
  def up
    sql = 'SELECT
        P.id AS product_id,
        (REGEXP_MATCHES(I.json, \'"country_of_origin":"([^"]+)"\'))[1] AS country_of_origin
      FROM
        spree_products P
        LEFT JOIN spree_product_import_items I ON P.id = I.product_id
      WHERE
        P.deleted_at IS NULL
        AND P.country_of_origin IS NULL'

    ActiveRecord::Base.connection.execute(sql).each do |row|
      product = Spree::Product.find(row['product_id'])
      product.country_of_origin = country_of_origin row['country_of_origin']
      product.save!

      puts "product_id: #{row['product_id']}"
      puts "country_of_origin: #{country_of_origin row['country_of_origin']}"
      puts $/
    end
  end

  def down
    # Can't undo
  end

  # Try to find the country by ISO code, then by name
  def country_of_origin value
    find = country_from_json_value value
    begin
      country = Spree::Country.find_by(iso: find)
      if country.nil?
        country = Spree::Country.find_by(name: find)
      end
      country.id
    rescue => e
      raise "Cannot find country by \"#{find}\": #{e}"
    end
  end

  # Country of origin is not always present, and does not always use standard ISO code, or
  # name as it appears in our system
  def country_from_json_value value
    case value
      when 'Chine'
        'CN'
      when 'Phillippines'
        'PH'
      when 'South Korea'
        'KR'
      when 'UK'
        'GB'
      when 'USA', 'the USA', 'USa', nil
        'US'
      else
        value
    end
  end
end
