Deface::Override.new(
    original: '9fb78af45a046627caa5187ab06e4cf1b6bdf986',
    virtual_path: "spree/layouts/admin",
    name: 'add_product_imports_to_admin_menu',
    insert_bottom: "[data-hook='admin_tabs']",
    text: "<ul class=\"nav nav-sidebar\"><%= main_menu_tree Spree.t(:product_imports), icon: 'import', sub_menu: 'product_import', url: '#sidebar-product-import' %>",
    disabled: false
)
