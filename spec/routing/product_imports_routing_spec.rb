require "rails_helper"

RSpec.describe ProductImportsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/product_imports").to route_to("product_imports#index")
    end

    it "routes to #new" do
      expect(:get => "/product_imports/new").to route_to("product_imports#new")
    end

    it "routes to #show" do
      expect(:get => "/product_imports/1").to route_to("product_imports#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/product_imports/1/edit").to route_to("product_imports#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/product_imports").to route_to("product_imports#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/product_imports/1").to route_to("product_imports#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/product_imports/1").to route_to("product_imports#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/product_imports/1").to route_to("product_imports#destroy", :id => "1")
    end

  end
end
