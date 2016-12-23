class ItemsController < ApplicationController
  before_action :set_item, only: [:show, :edit, :update, :destroy]
  before_action :set_article_for_order, only: [:add_item_to_storage]
  before_action :set_items_for_order, only: [:add_item_to_storage]
  # GET /items
  # GET /items.json
  def index
    @items = Item.all
  end

  # GET /items/1
  # GET /items/1.json
  def show
  end

  def storage_insert
    @items = Array.new
    render :partial => 'items/new_order'
  end

  def vehicle_insert

  end

  def add_item_to_storage

    @items = Array.new
    @i = nil
    @newItems.each do |i,k|
      item = Item.new
      item.setAmount k[:amount].to_i
      item.price = k[:price].to_f
      item.discount = k[:discount].to_f
      item.serial = k[:serial]
      item.state = k[:state].to_i
      item.expiringDate = k[:expiringDate]
      item.article = Article.find(k[:article].to_i)
      item.barcode = item.generateBarcode #SecureRandom.base58(10)
      @items << item
      @i = item
    end
    @i.printLabel

    # if params[:barcode] != ''
    unless @article.nil?
      item = Item.new
      item.article = @article
      item.setAmount 1
      item.barcode = item.generateBarcode #SecureRandom.base58(10)
      @items << item
    end

    if @save
      @items.each do |i|
        # i.transportDocument = @transportDocument
        OrderArticle.create!({order: @order, article: i.article, amount: i.amount})
        i.amount.times do
          item = Item.create!(i.attributes)
        end
      end
    end

    respond_to do |format|
      format.js { render :js, :partial => 'items/new_order' }
    end
  end

  def from_order
    render :partial => 'items/from_order'
  end

  # GET /items/new
  def new
    @item = Item.new
  end

  # GET /items/1/edit
  def edit
  end

  def output_office
    respond_to do |format|
      format.js { render :js, :partial => 'items/output_office' }
    end
  end

  # POST /items
  # POST /items.json
  def create
    @item = Item.new(item_params)

    respond_to do |format|
      if @item.save
        format.html { redirect_to @item, notice: 'Item was successfully created.' }
        format.json { render :show, status: :created, location: @item }
      else
        format.html { render :new }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /items/1
  # PATCH/PUT /items/1.json
  def update
    respond_to do |format|
      if @item.update(item_params)
        format.html { redirect_to @item, notice: 'Item was successfully updated.' }
        format.json { render :show, status: :ok, location: @item }
      else
        format.html { render :edit }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /items/1
  # DELETE /items/1.json
  def destroy
    @item.destroy
    respond_to do |format|
      format.html { redirect_to items_url, notice: 'Item was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_item
      @item = Item.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def item_params
      params.require(:item).permit(:article_id, :purchaseDate, :price, :price, :discount, :discount, :seral, :state, :notes, :expiringDate, :transportDocument_id)
    end

    def set_article_for_order
      if params['commit'] == '>' && params[:article].to_i > 0
        @article = Article.find(params[:article].to_i)
        @articles = Array.new
        @articles << @article
      elsif Article.where(barcode: params[:barcode]).count > 0
        @articles = Article.where(barcode: params[:barcode])
        @article = @articles.first
        @newArticle = false
      else
        @newArticle = true
        @article = Article.new({:barcode => params[:barcode]})
        @articles = Array.new
        @article.setBarcodeImage
        @articles << @article
      end
    end

    def set_items_for_order
      if params[:items].nil?
        @newItems = Array.new
      else
        @newItems = items_params
      end
    end


    def items_params
      @save = params['commit'] == 'Conferma ordine / DDT' ? true : false
      params.require(:items).tap do |itm|
        itm.permit(:article, :price, :discount, :serial, :state, :expiringDate, :amount)
      end
    end
end
