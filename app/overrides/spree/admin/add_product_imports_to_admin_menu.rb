
Deface::Override.new(
    :original => 'f75e9ec1ae2ef44ea72f69b18e9ef5b5584580a2',
    :virtual_path => "spree/layouts/admin",
    :name => 'add_product_imports_to_admin_menu',
    :insert_bottom => "[data-hook='admin_tabs']",
    :text => "<ul class='nav nav-sidebar'><%= tab :product_imports,  :url => admin_product_imports_url, :icon => 'import' %></ul>",
    :disabled => false
)
