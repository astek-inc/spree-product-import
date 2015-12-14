FactoryGirl.define do
  factory :file, :class => 'Spree::ImportFile' do |file|

  end

  factory :product_imports, :class => 'Spree::ProductImport' do

  end

  factory :product_import_with_file, :class => 'Spree::ProductImport' do
    after(:create) do |import|
      create(:file, import: import)
    end
  end
end

