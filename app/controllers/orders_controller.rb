class OrdersController < ApplicationController
  before_action :set_order, only: [:show, :edit, :update, :destroy]
  before_action :set_article_for_order, only: [:add_item_to_new_order]
  before_action :set_items_for_order, only: [:add_item_to_new_order]

  # GET /orders
  # GET /orders.json
  def index
    @orders = Order.all
  end

  # GET /orders/1
  # GET /orders/1.json
  def show
  end

  # GET /orders/new
  def new
    @order = Order.new
  end

  # GET /orders/1/edit
  def edit
  end

  # POST /orders
  # POST /orders.json
  def create
    @order = Order.new(order_params)

    respond_to do |format|
      if @order.save
        format.html { redirect_to @order, notice: 'Order was successfully created.' }
        format.json { render :show, status: :created, location: @order }
      else
        format.html { render :new }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  def new_order
    @order = Order.new
    @order.supplier = Company.find(2)
    @items = Array.new
    @transportDocument = TransportDocument.new
    @transportDocument.date = DateTime.now.to_date
    render :partial => 'items/new_order'
  end

  def scan_order
    render :partial => 'transport_documents/scan_document'
  end

  def add_item_to_new_order
    @order = Order.new
    @transportDocument = TransportDocument.new
    @items = Array.new
    @order.supplier = Company.get(params[:order]['supplier'])
    @order.date = params[:order][:purchaseDate]
    @transportDocument.number = params[:order][:transportDocument]
    @transportDocument.sender = Company.get(params[:order][:supplier])
    @transportDocument.vector = Company.get(params[:order][:vector])
    @transportDocument.date = params[:order][:purchaseDate]
    @newItems.each do |i,k|
      item = Item.new
      item.setAmount k[:amount].to_i
      item.price = k[:price].to_f
      item.discount = k[:discount].to_f
      item.serial = k[:serial]
      item.state = k[:state].to_i
      item.expiringDate = k[:expiringDate]
      item.article = Article.find(k[:article].to_i)
      item.barcode = SecureRandom.base58(10)
      @items << item
    end

    if params[:barcode] != ''
      item = Item.new
      item.article = @article
      item.setAmount 1
      item.barcode = SecureRandom.base58(10)
      @items << item
    end

    if @save
      @items.each do |i|
        # i.transportDocument = @transportDocument
        OrderArticle.create!({order: @order, article: i.article, amount: i.amount})
        i.amount.times do
          item = Item.create!(i.attributes)
          @transportDocument.items << item
        end
      end
      @transportDocument.save
      @order.transport_documents << @transportDocument
      @order.save
    end

    respond_to do |format|
      format.js { render :js, :partial => 'items/new_order' }
    end
  end

  # PATCH/PUT /orders/1
  # PATCH/PUT /orders/1.json
  def update
    respond_to do |format|
      if @order.update(order_params)
        format.html { redirect_to @order, notice: 'Order was successfully updated.' }
        format.json { render :show, status: :ok, location: @order }
      else
        format.html { render :edit }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /orders/1
  # DELETE /orders/1.json
  def destroy
    @order.destroy
    respond_to do |format|
      format.html { redirect_to orders_url, notice: 'Order was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order
      @order = Order.find(params[:id])
    end

    def set_article_for_order
      if Article.where(barcode: params[:barcode]).count > 0
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

    # Never trust parameters from the scary internet, only allow the white list through.
    def order_params
      params.require(:order).permit(:date, :supplier, :vector, :transportDocument, :purchaseDate)
    end

    def items_params
      @save = params['commit'].nil?? false : true
      params.require(:items).tap do |itm|
        itm.permit(:article, :price, :discount, :serial, :state, :expiringDate, :amount)
      end
    end
end
