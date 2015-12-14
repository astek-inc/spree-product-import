require 'rails_helper'

RSpec.describe "product_imports/new", type: :view do
  before(:each) do
    assign(:product_imports, ProductImport.new())
  end

  it "renders new product_imports form" do
    render

    assert_select "form[action=?][method=?]", product_imports_path, "post" do
    end
  end
end
