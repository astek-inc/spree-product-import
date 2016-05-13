Deface::Override.new(
    :original => 'b720ad784958259c77d83d6f906cbdac2439ade9',
    :virtual_path => 'spree/admin/products/_form',
    :name => 'add_expires_on_field_to_admin_product_form',
    :insert_after => 'div[data-hook="admin_product_form_available_on"]',
    :text => '<div data-hook="admin_product_form_expires_on">
        <%= f.field_container :expires_on, class: [\'form-group\'] do %>
          <%= f.label :expires_on, Spree.t(:expires_on) %>
          <%= f.error_message_on :expires_on %>
          <%= f.text_field :expires_on, value: datepicker_field_value(@product.expires_on), class: \'datepicker form-control\' %>
        <% end %>
      </div>'
)
