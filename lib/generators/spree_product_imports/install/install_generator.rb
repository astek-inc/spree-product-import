module SpreeProductImports
  module Generators
    class InstallGenerator < Rails::Generators::Base

      class_option :auto_run_migrations, :type => :boolean, :default => false

      def add_javascripts
        # append_file 'vendor/assets/javascripts/spree/frontend/all.js', "//= require spree/frontend/spree_product_imports\n"
        append_file 'vendor/assets/javascripts/spree/backend/all.js', "//= require spree/backend/spree_product_imports\n"
      end

      def add_stylesheets
        # inject_into_file 'vendor/assets/stylesheets/spree/frontend/all.css', " *= require spree/frontend/spree_product_imports\n", :before => /\*\//, :verbose => true
        inject_into_file 'vendor/assets/stylesheets/spree/backend/all.css', " *= require spree/backend/spree_product_imports\n", :before => /\*\//, :verbose => true
      end

      desc "Creates an initializer in your application's config/initializers dir"
      source_root File.expand_path('../../../templates', __FILE__)
      def copy_initializer
        template 'spree_product_imports.rb', 'config/initializers/spree_product_imports.rb'
      end

      def add_migrations
        run 'bundle exec rake railties:install:migrations FROM=spree_product_imports'
      end

      def run_migrations
        run_migrations = options[:auto_run_migrations] || ['', 'y', 'Y'].include?(ask 'Would you like to run the migrations now? [Y/n]')
        if run_migrations
          run 'bundle exec rake db:migrate'
        else
          puts "Skipping rake db:migrate, don't forget to run it!"
        end
      end
    end
  end
end
