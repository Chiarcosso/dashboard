class OrdersController < ApplicationController

  before_action :autocomplete_params, only: [:autocomplete_vehicles_plate_order,:add_item,:output,:add_item_to_new_order]
  before_action :set_order, only: [:show, :edit, :update, :destroy]
  before_action :set_article_for_order, only: [:add_item_to_new_order]
  before_action :set_items_for_order, only: [:add_item_to_new_order]
  before_action :output_params, only: [:add_item, :output]
  before_action :worksheet_params, only: [:edit_output]
  before_action :exit_params, only: [:exit_order,:confirm_order,:destroy_output_order, :print_pdf, :print_pdf_module]

  autocomplete :vehicle_information, :information, full: true, :id_element => '#vehicle_id'

  def autocomplete_person_filter
    # result = Array.new
    # Person.filter(params.permit(:term)[:term]).each do |p|
    #   result << { id: p.id.to_s, label: p.complete_name, value: p.complete_name, name: p.name}
    # end
    render :json => Person.filter(params.permit(:term)[:term]).map{ |p| { id: p.id.to_s, label: p.complete_name, value: p.id, name: p.name} }
  end
  # GET /orders
  # GET /orders.json
  def index
    search_params
    if @open_worksheets_filter
      @orders = OutputOrder.open_worksheets_filter #.paginate(:page => params[:page], :per_page => 5)
    else
      @orders = OutputOrder.limit(100) #.paginate(:page => params[:page], :per_page => 5)
    end
    if @search.nil? or @search == ''
      @orders = @orders.order(:processed => :asc, :created_at => :desc) #.paginate(:page => params[:page], :per_page => 5)
    else
      @orders = @orders.findByRecipient(@search) #.paginate(:page => params[:page], :per_page => 5)
    end

    respond_to do |format|
      format.js { render :js, :partial => 'orders/edit_output_orders' }
    end
  end

  def toggle_worksheet_closure
    ws = Worksheet.find(params[:id].to_i)
    # OutputOrder.where("destination_type = 'Worksheet' and destination_id = ?",ws.id).each do |oo|
    #   oo.update(:processed => !ws.opened?)
    # end
    ws.toggle_closure
    search_params
    if @open_worksheets_filter
      @orders = OutputOrder.open_worksheets_filter #.paginate(:page => params[:page], :per_page => 30)
    else
      @orders = OutputOrder.all #.paginate(:page => params[:page], :per_page => 30)
    end
    if @search.nil? or @search == ''
      @orders = @orders.order(:processed => :asc, :created_at => :desc) #.paginate(:page => params[:page], :per_page => 30)
    else
      @orders = @orders.findByRecipient(@search) #.paginate(:page => params[:page], :per_page => 30)
    end

    respond_to do |format|
      format.js { render :js, :partial => 'orders/edit_output_orders' }
    end
  end

  def edit_output
    @order = OutputOrder.findByRecipient(params.require(:code)).last
    @search = search_params.nil?? '' : search_params
    if @order.nil?
      @checked_items = Array.new
    else
      @checked_items = @order.items
    end
    # unless @newItem.nil?
    #   already_in = false
    #   @checked_items.each do |ci|
    #     if ci ==  @newItem
    #       already_in = true
    #     end
    #   end
    #   if already_in
    #     @checked_items -= [@newItem]
    #   else
    #     @checked_items << @newItem
    #   end
    # end

    unless @search.to_s == ''
      @selected_items = Item.available_items.unassigned.firstGroupByArticle(search_params,@checked_items)
    else
      @selected_items = Array.new
    end
    # render :partial => 'items/index'
    # @selected_items -= @checked_items
    # if @save
    #   order = OutputOrder.create(createdBy: current_user,destination_id: @recipient.id,destination_type: @destination)
    #   @checked_items.each do |ci|
    #     order.items << ci
    #   end
    #   # redirect_to storage_output_path
    # end
    respond_to do |format|
      # if @save
      #   @partial = 'storage/output_initial'
      #   format.js { render :js, :partial => 'storage/output_initial_js' }
      #   # format.js { render :js 'storage/index' }
      # else
        format.js { render :js, :partial => 'orders/output' }
      # end
    end
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
    respond_to do |format|
      format.js { render :js, :partial => 'orders/output' }
    end
  end

  def print_pdf
    respond_to do |format|
      format.pdf do
        pdf = @order.print
        send_data pdf.render, filename:
        "lista_ordine_uscita_nr_#{@order.id}.pdf",
        type: "application/pdf"
      end
    end
  end

  def print_pdf_module
    respond_to do |format|
      format.pdf do
        pdf = @order.print_module
        send_data pdf.render, filename:
        "modulo_dotazione_#{@order.id}.pdf",
        type: "application/pdf"
      end
    end
  end

  def output
    # @destination = output_params
    case @destination.to_sym
    when :Person
      @recipient = Person.new
    when :Worksheet
      @recipient = Worksheet.new
      @recipient.vehicle = Vehicle.new
    when :Vehicle
      @recipient = Vehicle.new
    when :Office
      @recipient = Office.all.first
    end
    @search = search_params.nil?? '' : search_params
    @checked_items = Array.new
    unless @search.to_s == ''
      @selected_items = Item.available_items.unassigned.firstGroupByArticle(search_params,@checked_items)
    else
      @selected_items = Array.new
    end
    # render :partial => 'items/index'
    respond_to do |format|
      format.js { render :js, :partial => 'orders/output' }
    end
  end

  def add_item
    # @destination = output_params
    # @search = search_params.nil?? '' : search_params
    search_params
    @checked_items = chk_list_params
    unless @newItem.nil?
      already_in = false
      @checked_items.each do |ci|
        if ci ==  @newItem
          already_in = true
        end
      end
      if already_in
        @checked_items -= [@newItem]
      else
        @checked_items << @newItem
      end
    end
    unless @search.to_s == ''
      @selected_items = Item.available_items.unassigned.firstGroupByArticle(@search,@checked_items)
    else
      @selected_items = Array.new
    end
    unless @newItems.nil?
      @newItems.each do |ni|
        @checked_items << ni
      end
    end
    unless @search.to_s == ''
      @selected_items = Item.available_items.unassigned.firstGroupByArticle(@search,@checked_items)
    else
      @selected_items = Array.new
    end
    # render :partial => 'items/index'
    # @selected_items -= @checked_items
    if @save
      get_order
      # @order = OutputOrder.findByCode(params.require(:code))
      if @order.nil?
        @order = OutputOrder.create(createdBy: current_user,destination_id: @recipient.id,destination_type: @destination, receiver: @receiver)
      end
      @order.receiver = @receiver
      @order.output_order_items.clear
      @checked_items.each do |ci|
        @order.items << ci
      end
      @order.save
      # redirect_to storage_output_path
    end
    respond_to do |format|
      if @save
        @partial = 'storage/output_initial'
        format.js { render :js, :partial => 'storage/output_initial_js' }
        # format.js { render :js 'storage/index' }
      else
        format.js { render :js, :partial => 'orders/output' }
      end
    end
  end

    def output_office
      @selected_items = Array.new
      @items = Item.filter(search_params)
      respond_to do |format|
        format.js { render :js, :partial => 'items/output' }
      end
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

  def exit_order
    render :partial => 'output_orders/exit'
  end

  def confirm_order
    @order.processed = true;
    if @order.save
      @order.items.each do |i|
        ir = ItemRelation.new
        ir.item = i
        ir.since = Date.current
        case @order.destination_type
        when 'Person'
          ir.person_id = @order.destination_id
        when 'Office'
          ir.office_id = @order.destination_id
        when 'Vehicle'
          ir.vehicle_id = @order.destination_id
        when 'Worksheet'
          ir.worksheet_id = @order.destination_id
        end
        ir.save
      end
      @msg = 'Ordine evaso'
    else
      @msg = 'Errore'
    end
      render :partial => 'layouts/messages'
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
      item.barcode = item.serial == '' ? SecureRandom.base58(10) : item.serial
      @items << item
    end

    if @save
      @items.each do |i|
        # i.transportDocument = @transportDocument
        OrderArticle.create({order: @order, article: i.article, amount: i.amount})
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
  def destroy_output_order

    if @order.destroy

      @msg = 'Ordine eliminato'
    else
      @msg = 'Errore'
    end
    # respond_to do |format|
    #   format.js { render :js, :partial => 'orders/output_orders' }
    # end
    index
  end

  private
    # Use callbacks to share common setup or constraints between actions.

    def autocomplete_params
      # vi = VehicleInformation.where(id: params[:vehicle_id].to_i)
      @vehicle = Vehicle.find_by_plate(params[:vehicle].to_s).first
      if @vehicle.nil?
        @vehicle = Vehicle.new
      end
    end

    def set_order
      @order = Order.find(params[:id])
    end

    def exit_params
      @order = OutputOrder.find(params.require(:id))
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
      if params['commit'].nil? || !params['no-commit'].nil?
        @save = false
      else
        @save = true
      end
      params.require(:items).tap do |itm|
        itm.permit(:article, :price, :discount, :serial, :state, :expiringDate, :amount)
      end
    end

    def output_params
      @destination = params.require(:destination)
      case params.require(:destination).to_sym
      when :Person
        @recipient = params[:recipient].nil?? Person.all.first : Person.find(params.require(:recipient).to_i)
      when :Office
        @recipient = params[:recipient].nil?? Office.all.first : Office.find(params.require(:recipient).to_i)
      when :Vehicle
        # @recipient = (params[:vrecipient].nil? || params[:vrecipient] == '')? Vehicle.find_by_plate((params[:vvehicle_id].nil? || params[:vvehicle_id] == '') ? '': params.require(:vvehicle_id)).first : Vehicle.find_by_plate(params.require(:vrecipient)).first
        if params[:vrecipient] == '' and params[:vvehicle_id] == ''
          @recipient = Vehicle.new
        else
          @recipient = (params[:vrecipient].nil? || params[:vrecipient] == '')? Vehicle.find_by_plate((params[:vvehicle_id].nil? || params[:vvehicle_id] == '') ? '': params.require(:vvehicle_id)).first : Vehicle.find_by_plate(params.require(:vrecipient)).first
        end
        if params[:precipient] == '' or params[:precipient].nil?
          @receiver = Person.new
        else
          @receiver = Person.find(params.require(:precipient).to_i)
        end
      when :Worksheet
        unless params[:recipient].nil? || params[:recipient] == ''
          @recipient = Worksheet.findByCode(params.require(:recipient))
          if @recipient.nil?
            unless params[:vehicle_id].to_i == 0
              vehicle = Vehicle.find(params[:vehicle_id].to_i)
            end
            if vehicle.nil?
              vehicle = Vehicle.find_by_plate(params[:vehicle]).first
            end
            if vehicle.nil?
              vehicle = Vehicle.new
            end
            @recipient = Worksheet.create(:code => params.require(:recipient), :vehicle => vehicle)
          elsif @recipient.vehicle.nil?
            vehicle = Vehicle.find_by_plate(params[:vehicle]).first
            # if vehicle.nil?
            #   vehicle = Vehicle.find(params.require(:vehicle_id))
            # end
            if vehicle.nil?
              vehicle = Vehicle.new
            end
            @recipient.vehicle = vehicle
            @recipient.save
          end
        else
          @recipient = Worksheet.new
          @recipient.vehicle = Vehicle.new
        end
      end
      unless params[:item].nil?
        @newItem = Item.find(params.require(:item).to_i)
        if params[:chamount].to_i > 1
          @newItems = Item.article(@newItem.article).not_this(@newItem).unassigned.limit(params[:chamount].to_i-1)
          # (params[:chamount].to_i - 1).times do
          #
          # end
        end
      end
    end

    def chk_list_params
      if params['commit'].nil? || !params['no-commit'].nil?
        @save = false
      else
        @save = true
      end
      case params.require(:destination).to_sym
      when :Person
        @recipient = params[:recipient].nil?? Person.all.first : Person.find(params.require(:recipient).to_i)
      when :Office
        @recipient = params[:recipient].nil?? Office.all.first : Office.find(params.require(:recipient).to_i)
      when :Vehicle
        # @recipient = (params[:vrecipient].nil? || params[:vrecipient] == '')? Vehicle.find_by_plate(params.require(:vvehicle_id)).first : Vehicle.find_by_plate(params.require(:vrecipient)).first
        if params[:vrecipient] == '' and params[:vvehicle_id] == ''
          @recipient = Vehicle.new
        else
          @recipient = (params[:vrecipient].nil? || params[:vrecipient] == '')? Vehicle.find_by_plate((params[:vvehicle_id].nil? || params[:vvehicle_id] == '') ? '': params.require(:vvehicle_id)).first : Vehicle.find_by_plate(params.require(:vrecipient)).first
        end
        if params[:precipient] == '' or params[:precipient].nil?
          @receiver = Person.new
        else
          @receiver = Person.find(params.require(:precipient).to_i)
        end
      when :Worksheet
        unless params[:recipient].nil? || params[:recipient] == ''
          @recipient = Worksheet.findByCode(params.require(:recipient))
          if @recipient.nil?
            vehicle = Vehicle.find(params.require(:vehicle_id).to_i)
            if vehicle.nil?
              vehicle = Vehicle.find_by_plate(params.require(:vehicle)).first
            end
            if vehicle.nil?
              vehicle = Vehicle.new
            end
            @recipient = Worksheet.create(:code => params.require(:recipient), :vehicle => vehicle)
          elsif @recipient.vehicle.nil?
            vehicle = Vehicle.find_by_plate(params.require(:vehicle)).first
            # if vehicle.nil?
            #   vehicle = Vehicle.find(params.require(:vehicle_id))
            # end
            if vehicle.nil?
              vehicle = Vehicle.new
            end
            @recipient.vehicle = vehicle
            @recipient.save
          end
        else
          @recipient = Worksheet.new
          @recipient.vehicle = Vehicle.new
        end
      end
      unless params[:items].nil?
        itms = Array.new
        params.require(:items).tap do |itm|
          itm.each do |i|
            id = i.require(:id)
            unless id.nil?
              itms << Item.find(id)
            end
          end
        end
        itms.reverse
      else
        Array.new
      end
    end

    def worksheet_params
      code = (params[:code].nil? or params[:code] == '') ? params.require(:recipient) : params.require(:code)
      unless code.nil? or code == ''
        @recipient = Worksheet.findByCode(code)
        @destination = 'Worksheet'
        unless @recipient.nil?
          @order = OutputOrder.findByRecipient(@recipient.code).last
        else
          @order = OutputOrder.new
          @recipient = Worksheet.new(:code => code, :vehicle => Vehicle.new)
        end
      end
    end

    def get_order
      case params[:destination]
      when 'Worksheet'
        worksheet_params
      else
        nil
      end
    end

    def search_params
      unless params[:search].nil? or params[:search] == ''
        if params[:search].size == 0
          @search = nil
        end
        @search = params.require(:search)
      end
      unless params[:open_worksheets_filter].nil? or params[:open_worksheets_filter] == ''
        @open_worksheets_filter = params[:open_worksheets_filter] == 'on' ? true : false
      end
    end
end
