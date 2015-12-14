require 'rails_helper'

RSpec.describe "product_imports/edit", type: :view do
  before(:each) do
    @product_import = assign(:product_imports, ProductImport.create!())
  end

  it "renders the edit product_imports form" do
    render

    assert_select "form[action=?][method=?]", product_import_path(@product_import), "post" do
    end
  end
end
