class ArticlesController < ApplicationController
  before_action :set_article, only: [:show, :edit, :update, :destroy, :list_categories]
  before_action :set_categories, only: [:list_categories]

  require 'barby/outputter/cairo_outputter'
  # require 'barby/outputter/png_outputter'
  require 'barby/barcode/ean_13'

  # GET /articles
  # GET /articles.json
  def index
    @articles = Article.all
  end

  # GET /articles/1
  # GET /articles/1.json
  def show
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
        format.js { render :partial => 'articles/incomplete' }
      else
        format.js { render :partial => 'articles/to_categories' }
        format.json { render :show, status: :created, location: @article }
      end
    end
  end

  def incomplete
    render :partial => 'articles/incomplete'
  end

  # GET /articles/new
  def new
    @article = Article.new
    # render :partial => 'articles/new'
    respond_to do |format|
      format.js { render :partial => 'articles/new' }
      format.html { render :partial => 'articles/new' }
    end
  end

  # GET /articles/1/edit
  def edit
    respond_to do |format|
      format.js { render :partial => 'articles/new'}
      format.json { render :show, status: :created, location: @article }
    end
  end

  # POST /articles
  # POST /articles.json
  def create
    @article = Article.new(article_params)

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

        format.js { render :partial => 'articles/to_categories', notice: 'Articolo modificato.' }
        format.json { render :show, status: :created, location: @article }
      else
        format.js { render :partial => 'articles/incomplete', notice: 'Impossibile modificare articolo.' }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /articles/1
  # DELETE /articles/1.json
  def destroy
    @article.destroy
    respond_to do |format|
      format.html { redirect_to articles_url, notice: 'Article was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.


    def set_article
      @article = Article.find(params[:id])
      if barcode = @article.checkBarcode
        @blob = Barby::CairoOutputter.new(barcode).to_png #Raw PNG data
        File.write("public/images/#{@article.barcode}.png", @blob)
      else
        @article.barcode = 'Codice non valido'
      end
    end

    def set_categories
      params.require(:categories)
      params[:categories].each do |c|
        c = c.to_i
      end
      params
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def article_params
      params.require(:article).permit(:barcode, :manufacturerCode, :name, :description, :containedAmount, :minimalReserve, :positionCode)
    end
end
