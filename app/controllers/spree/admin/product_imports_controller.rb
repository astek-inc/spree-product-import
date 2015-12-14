module Spree::Admin
  class ProductImportsController < ApplicationController
    before_action :set_product_import, only: [:show, :edit, :update, :destroy, :import]

    # GET /product_imports
    def index
      @product_imports = Spree::ProductImport.all
    end

    # GET /product_imports/1
    def show
      @csv = []
      @product_import.file.get_rows { |row| @csv << row }
      @headers = @csv.first.keys
    end

    # GET /product_imports/new
    def new
      @product_import = Spree::ProductImport.new
      @product_import.build_file
    end

    # GET /product_imports/1/edit
    def edit
      @product_import.build_file
    end

    # POST /product_imports
    def create
      @product_import = Spree::ProductImport.new(product_import_params)

      if @product_import.save
        redirect_to [:admin, @product_import], notice: 'Product import was successfully created.'
      else
        render :new
      end
    end

    def import
      @product_import.import
      respond_to  do |format|
        [:admin, @product_import]
      end
    end


    # PATCH/PUT /product_imports/1
    def update
      if @product_import.update(product_import_params)
        redirect_to [:admin, @product_import], notice: 'Product import was successfully updated.'
      else
        render :edit
      end
    end

    # DELETE /product_imports/1
    def destroy
      @product_import.destroy
      redirect_to admin_product_imports_url, notice: 'Product import was successfully destroyed.'
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_product_import
        @product_import = Spree::ProductImport.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def product_import_params
        params.require(:product_import).permit( :file, file_attributes: [:csv_file] )
      end
  end
end
