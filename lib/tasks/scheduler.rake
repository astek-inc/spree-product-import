desc 'Remove expired products from site.'
task :remove_expired_products => :environment do
  # puts 'Removing expired products...'
  Spree::Product.where('expires_on < ?', Time.now).destroy_all
  # puts 'Done.'
end
