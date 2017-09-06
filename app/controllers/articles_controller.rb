class ArticlesController < ApplicationController
  before_action :set_article, only: [:show, :edit, :update, :destroy, :list_categories, :print]
  before_action :set_categories, only: [:list_categories]

  autocomplete :company, :name, full: true
  # GET /articles
  # GET /articles.json
  def index
    if search_params.nil? || search_params == ""
      @filteredArticles = Array.new
    else
      @filteredArticles = Article.filter(search_params)
    end
  end

  # GET /articles/1
  # GET /articles/1.json
  def show
  end

  def print
    @article.printLabel
  end

  def print_inventory
    respond_to do |format|
      format.pdf do
        pdf = Article.inventory(find_params)
        send_data pdf.render, filename: "inventario_test.pdf", type: "application/pdf"
      end
    end
  end

  def print_reserve
    respond_to do |format|
      format.pdf do
        pdf = Article.reserve
        byebug
        send_data pdf.render, filename: "scorte.pdf", type: "application/pdf"
      end
    end
  end

  def list_categories

    @categories = Array.new
    @selectedCategories = params[:categories]
    @selectedCategories.each do |pl|
      f = true
      ArticleCategory.find(pl.to_i).parentCategories.each do |p|
        if p.id == pl.to_i
          f = false
        end
        if f
          @selectedCategories << p.id.to_s
        end
      end
    end
    ArticleCategory.root.each do |c|
      @categories << c
      @categories.concat c.childrenTree(@selectedCategories.uniq)
    end

    respond_to do |format|
      if params["commit"] == "Salva"
        @article.categories.delete_all
        @selectedCategories.each do |sc|
          ac = ArticleCategory.find(sc.to_i)
          if (!@article.categories.include? ac) && (ac.last? @selectedCategories)
            @article.categories << ac
          end
        end
        @filteredArticles = Array.new
        format.js { render :partial => 'articles/incomplete' }
      else
        format.js { render :partial => 'articles/to_categories' }
        format.json { render :show, status: :created, location: @article }
      end
    end
  end

  def incomplete
    if search_params.nil? || search_params == ""
      @filteredArticles = Array.new
    else
      @filteredArticles = Article.filter(search_params)
    end
    render :partial => 'articles/incomplete'
  end

  # GET /articles/new
  def new
    @article = Article.new
    # render :partial => 'articles/new'
    unless barcode_params.nil?
      @article.barcode = barcode_params
    end
    respond_to do |format|
      format.js { render :partial => 'articles/new' }
      format.html { render :partial => 'articles/new' }
    end
  end

  # GET /articles/1/edit
  def edit
    @search = find_params
    respond_to do |format|
      format.js { render :partial => 'articles/new'}
      format.json { render :show, status: :created, location: @article }
    end
  end

  # POST /articles
  # POST /articles.json
  def create
    @article = Article.new(article_params)
    @article.manufacturer = @manufacturer
    respond_to do |format|
      if @article.save
        # format.html { redirect_to @article, notice: 'Article was successfully created.' }
        @article = Article.new

        # @outputter = Barby::CairoOutputter.new(@article.barcode)
        format.js { render :partial => 'articles/new', notice: 'Articolo creato.' }
        format.json { render :show, status: :created, location: @article }
      else
        format.js { render :partial => 'articles/new', notice: 'Impossibile creare articolo.' }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /articles/1
  # PATCH/PUT /articles/1.json
  def update
    respond_to do |format|
      if @article.update(article_params)
        @article.manufacturer = @manufacturer
        @article.save
        @categories = Array.new
        @selectedCategories = Array.new
        @article.categories.each do |ct|
          @selectedCategories << ct.id.to_s
        end

        @selectedCategories.each do |pl|
          f = true
          ArticleCategory.find(pl.to_i).parentCategories.each do |p|
            if p.id == pl.to_i
              f = false
            end
            if f
              @selectedCategories << p.id.to_s
            end
          end
        end
        ArticleCategory.root.each do |c|
          @categories << c
          @categories.concat c.childrenTree(@selectedCategories.uniq)
        end
        @search = search_params
        @filteredArticles = Article.filter(@search)
        if params["commit"] == "Salva"
          format.js { render :partial => 'articles/incomplete', notice: 'Articolo modificato.' }
        else
          format.js { render :partial => 'articles/to_categories', notice: 'Articolo modificato.' }
        end
      else
        format.js { render :partial => 'articles/incomplete', notice: 'Impossibile modificare articolo.' }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /articles/1
  # DELETE /articles/1.json
  def destroy
    @search = find_params
    @filteredArticles = Article.filter(@search)
    respond_to do |format|
      begin @article.destroy
        format.js { render :partial => 'articles/incomplete', notice: 'Articolo eliminato.' }
      rescue
        format.js { render :partial => 'articles/incomplete', notice: 'Impossibile eliminare articolo.' }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.

    def barcode_params
      unless params[:barcode].nil?
        params.require(:barcode)
      end
    end

    def set_article
      @article = Article.find(params.require(:id))
      @article.setBarcodeImage
    end

    def set_categories
      params.require(:categories)
      params[:categories].each do |c|
        c = c.to_i
      end
      params
    end

    def find_params
      unless params[:search].nil? || params[:search] == ''
        Base64.decode64(params.require(:search))
      end
    end

    def search_params
      unless params[:search].nil? || params[:search] == ''
        @search = params.require(:search)
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def article_params

      unless params[:manufacturer] == ''
        # @manufacturer = Company.find(:all,:conditions => ['name LIKE ?', "#{params[:manufacturer]}"])
        @manufacturer = Company.where('name LIKE ?', "#{params[:manufacturer]}").first
        if @manufacturer.nil?
          @manufacturer = Company.create(:name => params[:manufacturer])
        end
      else
        @manufacturer = Company.first
      end
      params[:article][:measure_unit] = params[:article][:measure_unit].to_i
      params.require(:article).permit(:barcode, :manufacturerCode, :name, :description, :containedAmount, :minimalReserve, :position_code, :measure_unit)
    end
end
