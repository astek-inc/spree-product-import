desc 'Remove expired products from site.'
task :remove_expired_products => :environment do
  # puts 'Removing expired products...'
  Spree::Product.where('expires_on < ?', Time.now).destroy_all
  # puts 'Done.'
end

desc 'Process any pending imports in batches of ten items'
task process_pending_product_import_items: :environment do

  # puts 'Begin'

  imports_to_review = []
  items_to_process = []

  # puts 'Checking pending imports'
  Spree::ProductImport.pending.each do |import|

    current_count = items_to_process.size
    import.product_import_items.each do |item|
      items_to_process << item if item.state == Spree::ProductImportItem::STATE_PENDING
      break if items_to_process.size >= 10
    end

    # If we've added any items from this import to our queue, mark it for review
    if items_to_process.size > current_count
      imports_to_review << import
      current_count = items_to_process.size
    end
    break if items_to_process.size >= 10

  end

  # puts 'Processing items'
  items_to_process.each do |item|
    # pp item

    item.create_product
  end

  # puts 'Reviewing imports'
  imports_to_review.each do |import|
    # pp import

    if Spree::ProductImportItem.where(product_import_id: import.id, state: [Spree::ProductImportItem::STATE_PENDING, Spree::ProductImportItem::STATE_ERROR]).empty?
      import.state = Spree::ProductImport::STATE_COMPLETE
      import.completed_at = DateTime.now
      import.save!
    end
  end

  # puts 'Done!'

end
