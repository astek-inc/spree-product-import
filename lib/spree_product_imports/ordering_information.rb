module SpreeProductImports
  class OrderingInformation

    # Assign items for "Ordering Information" box on product page
    def self.assign product, item_data

        product.set_order_info_item('Please confirm availability -- 3-8 week lead time')

        case item_data['type']
          when 'Wallpaper'
            product.set_order_info_item('Colors may vary - please order sample')

            if item_data['default_qnty'].to_i == 2
              product.set_order_info_item('Double roll')
            end
        end

        unless item_data['printtoorder'].nil?
          product.set_order_info_item('Unprinted margins')
          product.set_order_info_item('Customization available')
        end

    end
  end
end
