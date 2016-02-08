
Deface::Override.new(
  :virtual_path => "spree/layouts/admin",
  :name => 'add_product_imports_to_admin_menu',
  :insert_bottom => "[data-hook='admin_tabs']",
  :text => "<ul class='nav nav-sidebar'><%= tab :product_imports,  :url => admin_product_imports_url, :icon => 'import' %></ul>",
  :disabled => false
)
