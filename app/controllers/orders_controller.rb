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
    @transportDocument = TransportDocument.new
    @transportDocument.date = DateTime.now.to_date
    render :partial => 'items/new_order'
  end

  def add_item_to_new_order
    @order = Order.new
    @transportDocument = TransportDocument.new
    @order.supplier = Company.get(params[:order]['supplier'])
    @order.date = params[:order][:purchaseDate]
    @transportDocument.number = params[:order][:transportDocument]
    @transportDocument.sender = Company.get(params[:order][:supplier])
    @transportDocument.vector = Company.get(params[:order][:vector])
    @transportDocument.date = params[:order][:purchaseDate]
    @items.each do |i,k|
      item = Item.new
      item.setAmount k[:amount].to_i
      item.price = k[:price].to_f
      item.discount = k[:discount].to_f
      item.serial = k[:serial]
      item.state = k[:state].to_i
      item.expiringDate = k[:expiringDate]
      item.article = Article.find(k[:article].to_i)
      @order.items << item
    end
    item = Item.new
    item.article = @article
    item.setAmount 1
    @order.items << item
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
      @article = Article.where(barcode: params[:barcode]).first
    end

    def set_items_for_order
      if params[:items].nil?
        @items = Array.new
      else
        @items = params[:items]
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def order_params
      params.require(:order).permit(:date, :supplier, :vector, :transportDocument, :purchaseDate)
    end
end
