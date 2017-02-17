module SpreeProductImports
  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  class Configuration
    attr_accessor :admin_product_imports_per_page

    def initialize
      @admin_product_imports_per_page = 15
    end
  end
end
