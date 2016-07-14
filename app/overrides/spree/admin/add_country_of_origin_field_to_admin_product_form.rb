Deface::Override.new(
    :original => 'a2e0e4758a8c786c5c4ab24fe7e21b638c386d5e',
    :virtual_path => 'spree/admin/products/_form',
    :name => 'add_country_of_origin_field_to_admin_product_form',
    :insert_bottom => 'div[data-hook="admin_product_form_left"]',
    :text => '<div data-hook="admin_product_form_country_of_origin">
        <%= f.field_container :country_of_origin, class: [\'form-group\'] do %>
          <%= f.label :country_of_origin, Spree.t(:country_of_origin) %>
          <%= f.collection_select(:country_of_origin, Spree::Country.order(:name), :id, :name,
            {include_blank: Spree.t(\'match_choices.none\')},
            {class: \'select2\', disabled: (cannot? :edit, Spree::Country)})
          %>
          <%= f.error_message_on :country_of_origin %>
        <% end %>
      </div>'
)
