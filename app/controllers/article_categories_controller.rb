class ArticleCategoriesController < ApplicationController
  before_action :set_article_category, only: [:show, :edit, :update, :destroy]
  before_action :article_category_manage, only: [:manage]
  # GET /article_categories
  # GET /article_categories.json
  def index
    respond_to do |format|
      format.js { render :partial => 'article_categories/index' }
      format.html { render :partial => 'article_categories/index' }
    end
  end

  def manage
    parent = ArticleCategory.find(params[:relation][:parent].to_i)
    if params[:relation][:child].to_i == 0
      child = ArticleCategory.create!(:name => params[:relation][:child])
    else
      child = ArticleCategory.find(params[:relation][:child].to_i)
    end

    if parent != child
      if parent.childCategories.to_a.index(child).nil? && !child.hasDirectRelation?(parent)
        parent.childCategories << child
      else
        parent.childCategories.delete(child)
      end
    end

    respond_to do |format|
      format.js { render :partial => 'article_categories/index' }
      # format.html { render :partial => 'article_categories/index' }
    end
  end
  # GET /article_categories/1
  # GET /article_categories/1.json
  def show
  end

  # GET /article_categories/new
  def new
    @article_category = ArticleCategory.new
  end

  # GET /article_categories/1/edit
  def edit
  end

  # POST /article_categories
  # POST /article_categories.json
  def create
    @article_category = ArticleCategory.new(article_category_params)

    respond_to do |format|
      if @article_category.save
        format.html { redirect_to @article_category, notice: 'Article category was successfully created.' }
        format.json { render :show, status: :created, location: @article_category }
      else
        format.html { render :new }
        format.json { render json: @article_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /article_categories/1
  # PATCH/PUT /article_categories/1.json
  def update
    respond_to do |format|
      if @article_category.update(article_category_params)
        format.html { redirect_to @article_category, notice: 'Article category was successfully updated.' }
        format.json { render :show, status: :ok, location: @article_category }
      else
        format.html { render :edit }
        format.json { render json: @article_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /article_categories/1
  # DELETE /article_categories/1.json
  def destroy
    @article_category.destroy
    respond_to do |format|
      format.js { render :partial => 'article_categories/index' }
      format.html { render :partial => 'article_categories/index' }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_article_category
      @article_category = ArticleCategory.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def article_category_params
      params.require(:article_category).permit(:name)
    end

    def article_category_manage
      params.require(:relation).permit(:parent,:child)
    end
end
