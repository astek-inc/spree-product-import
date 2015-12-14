require 'spec_helper'

RSpec.describe Spree::ImportFile, type: :model do

  let(:headers) do
    ["deleted_at", "id", "name", "description", "available_on", "slug", "meta_description", "meta_keywords",
     "tax_category_id", "shipping_category_id", "created_at", "updated_at", "promotionable", "meta_title"]
  end

  it 'has valid factory' do
    expect(build(:file)).to be_valid
  end

  it 'allows uploads new file' do
    fp = File.open ("#{__dir__}/../../factories/template.csv")
    expect(build(:file, csv_file: fp)).to be_valid
  end

  it 'gets an array of file headers' do
    fp = File.open ("#{__dir__}/../../factories/template.csv")
    columns = create(:file, csv_file: fp).get_column_names

    expect(columns).to eq(headers)
  end

  it 'fails when uploaded file is missing headers' do
  end

end
