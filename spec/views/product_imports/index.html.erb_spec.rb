require 'rails_helper'

RSpec.describe "product_imports/index", type: :view do
  before(:each) do
    assign(:product_imports, [
      ProductImport.create!(),
      ProductImport.create!()
    ])
  end

  it "renders a list of product_imports" do
    render
  end
end
