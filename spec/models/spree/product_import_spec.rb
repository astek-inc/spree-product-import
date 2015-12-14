require "spec_helper"

RSpec.describe Spree::ProductImport, type: :model do

  let(:product_data) {

  }

  it 'has valid factory' do
    expect(create(:product_imports)).to be_valid
  end

  it 'allows a file attachment from parent class' do
    @import = create(:product_import_with_file)
    expect(@import).to be_valid
    expect(@import.file.class.name).to eq('Spree::ImportFile')
  end

  it 'imports a list of products from csv' do
    fp = File.open ("#{__dir__}/../../factories/product_template.csv")
    file = create(:file, csv_file: fp)
    product = create(:product_imports, file: file)

    expect(product.import).to contain_exactly(2)
  end

end
