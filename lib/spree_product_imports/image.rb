module SpreeProductImports
  class Image

    # Use pattern to generate filename from SKU.
    def self.filename_from_sku(sku, filename_pattern)
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
