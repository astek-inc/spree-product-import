require 'rails_helper'

RSpec.describe "product_imports/show", type: :view do
  before(:each) do
    @product_import = assign(:product_imports, ProductImport.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
