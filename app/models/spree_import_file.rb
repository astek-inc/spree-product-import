class SpreeImportFile < SpreeImport
  belongs_to :user, class: 'Spree::User'
end
