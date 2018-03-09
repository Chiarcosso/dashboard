class OrdersController < ApplicationController
  include ErrorHelper
  require 'output_order_item'

  before_action :autocomplete_params, only: [:autocomplete_vehicles_plate_order,:add_item,:output,:add_item_to_new_order]
  before_action :set_order, only: [:show, :edit, :update, :destroy]
  before_action :set_article_for_order, only: [:add_item_to_new_order]
  before_action :set_items_for_order, only: [:add_item_to_new_order]
  before_action :output_params, only: [:add_item, :output, :edit_output]
  before_action :worksheet_params, only: [:edit_ws_output]
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

  def edit_ws_output
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

  def edit_output
    # @order = OutputOrder.find_by_recipient(params.require(:search))

    worksheet_params unless params[:search].nil? or params[:destination] != 'Worksheet'
    @order = OutputOrder.find_by_recipient(@recipient) if @order.nil?
    @search = search_params.nil?? '' : search_params
    if @order.nil? or @order.output_order_items.empty?
      @checked_items = Array.new
    else
      @checked_items = @order.output_order_items
    end
    # unless @newItem.nil?
    #   already_in = false
    #   @checked_items.each do |ci|
    #     if ci.item ==  @newItem
    #       already_in = true
    #     end
    #   end
    #   if already_in
    #     ci.remaining_quantity
    #   else
    #     @checked_items << @newItem
    #   end
    # end
    unless @search.to_s == ''
      @selected_items = Item.next_available_items(@search,@checked_items,@from.to_i)
    else
      @selected_items = Array.new
    end
    # unless @search.to_s == ''
    #   @selected_items = Item.available_items.unassigned.firstGroupByArticle(search_params,@checked_items)
    # else
    #   @selected_items = Array.new
    # end
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
      @receiver = Person.new
    when :Office
      @recipient = Office.all.first
    end
    @search = search_params.nil?? '' : search_params
    @checked_items = Array.new
    unless @search.to_s == ''
      @selected_items = Item.next_available_items(@search,@checked_items,0)
    else
      @selected_items = Array.new
    end
    get_order
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
    # unless @newItem.nil?
    #
    #   already_in = false
    #   @checked_items.each do |ci|
    #     if ci.item ==  @newItem
    #       already_in = true
    #     end
    #   end
    #   if already_in
    #     @checked_items -= @newItems
    #   else
    #     @checked_items += @newItems
    #   end
    # end
    # chk = @checked_items.map { |ooi| Item.find(ooi.item) }
    unless @search.to_s == ''
      @selected_items = Item.next_available_items(@search,@checked_items,@from.to_i)
    else
      @selected_items = Array.new
    end
    # unless @newItems.nil?
    #   @newItems.each do |ni|
    #     @checked_items << ni
    #   end
    # end
    # unless @search.to_s == ''
    #   if (@from == '0')
    #     @selected_items = Item.available_items.unassigned.firstGroupByArticle(@search,@checked_items)
    #   else
    #     @selected_items = Item.firstGroupByArticle(@search,@checked_items,Item.assigned_to(Office.find(@from.to_i)))
    #   end
    # else
    #   @selected_items = Array.new
    # end
    # render :partial => 'items/index'
    # @selected_items -= @checked_items

      get_order
    if @save
      # @order = OutputOrder.findByCode(params.require(:code))
      if @order.id.nil?
        @order = OutputOrder.create(createdBy: current_user,destination_id: @recipient.id,destination_type: @recipient.class, receiver: @receiver)
      end
      @order.receiver = @receiver
      @order.destination = @recipient
      # @order.output_order_items.clear
      # @order.recover_items
      @order.output_order_items.each do |ooi|
        # if @checked_items.include? ooi
        #   nooi = @checked_items.find { |oo| oo == ooi }
        #   ooi.update(quantity: nooi.quantity)
        # else
        #   ooi.destroy
        # end
        ooi.destroy unless @checked_items.include? ooi
      end

      @checked_items.each do |ci|
        if @order.to_mobile_workshop?
          MobileWorkshopItem.create(storage_item: Item.find(ci.item.id), mobile_workshop: @recipient, remaining_quantity: ci.quantity)
        end
        rq = ci.item.remaining_quantity - ci.quantity
        rq = 0 if rq < 0
        ci.item.update(remaining_quantity: rq)
        ci.save
        @order.output_order_items << ci unless @order.output_order_items.include? ci

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

  # def add_item_to_new_order
  #   @order = Order.new
  #   @transportDocument = TransportDocument.new
  #   @items = Array.new
  #   @order.supplier = Company.get(params[:order]['supplier'])
  #   @order.date = params[:order][:purchaseDate]
  #   @transportDocument.number = params[:order][:transportDocument]
  #   @transportDocument.sender = Company.get(params[:order][:supplier])
  #   @transportDocument.vector = Company.get(params[:order][:vector])
  #   @transportDocument.date = params[:order][:purchaseDate]
  #   @newItems.each do |i,k|
  #     item = Item.new
  #     item.setAmount k[:amount].to_i
  #     item.price = k[:price].to_f
  #     item.discount = k[:discount].to_f
  #     item.serial = k[:serial]
  #     item.state = k[:state].to_i
  #     item.expiringDate = k[:expiringDate]
  #     item.article = Article.find(k[:article].to_i)
  #     item.barcode = SecureRandom.base58(10)
  #     @items << item
  #   end
  #
  #   if params[:barcode] != ''
  #     item = Item.new
  #     item.article = @article
  #     item.setAmount 1
  #     item.barcode = item.serial == '' ? SecureRandom.base58(10) : item.serial
  #     @items << item
  #   end
  #
  #   if @save
  #     @items.each do |i|
  #       # i.transportDocument = @transportDocument
  #       OrderArticle.create({order: @order, article: i.article, amount: i.amount})
  #       i.amount.times do
  #         item = Item.create!(i.attributes)
  #         @transportDocument.items << item
  #       end
  #     end
  #     @transportDocument.save
  #     @order.transport_documents << @transportDocument
  #     @order.save
  #   end
  #
  #   respond_to do |format|
  #     format.js { render :js, :partial => 'items/new_order' }
  #   end
  # end

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
      @vehicle = Vehicle.find_by_plate(params[:vehicle].to_s)#.first
      if @vehicle.nil?
        @vehicle = Vehicle.new
      end
    end

    def chk_list_params
      if params['commit'].nil? || !params['no-commit'].nil?
        @save = false
      else
        @save = true
      end
      case params.require(:code).to_sym
      when :Person
        @recipient = params[:recipient].nil?? Person.all.first : Person.find(params.require(:recipient).to_i)
      when :Office
        @recipient = params[:recipient].nil?? Office.all.first : Office.find(params.require(:recipient).to_i)
      when :Vehicle
        # @recipient = (params[:vrecipient].nil? || params[:vrecipient] == '')? Vehicle.find_by_plate(params.require(:vvehicle_id)).first : Vehicle.find_by_plate(params.require(:vrecipient)).first
        if params[:vrecipient] == '' and params[:vvehicle_id] == ''
          @recipient = Vehicle.new
        else
          @recipient = (params[:vrecipient].nil? || params[:vrecipient] == '')? Vehicle.find_by_plate((params[:vvehicle_id].nil? || params[:vvehicle_id] == '') ? '': params.require(:vvehicle_id)) : Vehicle.find_by_plate(params.require(:vrecipient))#.first
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
              vehicle = Vehicle.find_by_plate(params.require(:vehicle))#.first
            end
            if vehicle.nil?
              vehicle = Vehicle.new
            end
            @recipient = Worksheet.create(:code => params.require(:recipient).upcase, :vehicle => vehicle)
          elsif @recipient.vehicle.nil?
            vehicle = Vehicle.find_by_plate(params.require(:vehicle))#.first
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
      @order = OutputOrder.new(:destination => @recipient,:destination_type => params.require(:code))
      get_output_items

    end

    def exit_params
      @order = OutputOrder.find(params.require(:id))
    end

    def get_order
      case params[:destination]
      when 'Worksheet'
        worksheet_params unless params[:recipient] == '' or params[:recipient].nil?
      else
        if params[:order_id].nil? or params[:order_id].to_i == 0
          @order = OutputOrder.new
        else
          @order = OutputOrder.find(params.require(:order_id).to_i)
          @recipient = @order.destination if @recipient.nil?
          if params[:code] = 'Vehicle'
            @receiver = @order.receiver if @receiver.nil?
          end
        end
      end
    end

    def get_output_items
      unless params[:item].nil?
        @newItem = Item.find(params.require(:item).to_i)
      end

      itms = Array.new
      unless params[:items].nil?
        params.require(:items).tap do |itm|
          # ooi_in = false
          itm.each do |i|
            id = i.require(:id)
            unless id.nil?
              foo = OutputOrderItem.new #workaround for YAML.load bug
              ooi = YAML::load(Base64.decode64(id))
              # itms << YAML::load(Base64.decode64(id))
              # ooi.item.remaining_quantity -= ooi.quantity
              itms << ooi
              # new_ooi = nil
              # itms.each do |i|
              #   if i.item.id == ooi.item.id
              #     i.quantity += ooi.quantity
              #     i.item.remaining_quantity -= ooi.quantity
              #     if i.item.remaining_quantity < 0
              #       am = i.item.remaining_quantity.abs
              #       i.item.remaining_quantity = 0
              #       i.quantity -= am
              #       new_ooi = OutputOrderItem.new(item: @newItem.find_next_usable(itms.map { |ooi| ooi.item }), output_order: @order, quantity: am)
              #     end
              #     ooi_in = true
              #   end
              # end
              # itms << new_ooi unless new_ooi.nil?
              # itms << ooi unless ooi_in
            end
          end
        end
      end
      unless @newItem.nil?
        amount = params.require(:chamount).to_f.abs
        av = @newItem.article.actual_availability(@checked_items)
        amount = av if amount > av
        while amount > 0
          new_itms = Array.new
          itms.each do |i|
            if i.item.id == @newItem.id
              if i.item.remaining_quantity >= amount
                i.item.remaining_quantity -= amount
                i.quantity += amount
                amount = 0
                break
              else
                amount -= i.item.remaining_quantity
                i.quantity += i.item.remaining_quantity
                i.item.remaining_quantity = 0
                @newItem = i.item.find_next_usable ((itms+new_itms).map { |ooi| ooi.item }),@from.to_i
                # break if @newItem.nil?
              end
            end
          end
          if amount > 0
            if @newItem.remaining_quantity >= amount
              ni = @newItem.clone
              ni.remaining_quantity -= amount
              new_itms << OutputOrderItem.new(item: ni, output_order: @order, quantity: amount)
              amount = 0
            else
              # ni = @newItem.clone
              q = @newItem.remaining_quantity
              amount -= @newItem.remaining_quantity
              @newItem.remaining_quantity = 0
              new_itms << OutputOrderItem.new(item: @newItem, output_order: @order, quantity: q)
              puts " --- #{@newItem.inspect}"
              @newItem = @newItem.find_next_usable ((itms+new_itms).map { |ooi| ooi.item }),@from.to_i
              puts " +++ #{@newItem.inspect}"
              break if @newItem.nil?
            end
          end
          itms += new_itms
          new_itms = Array.new
        end
      end
      #   new_item_in = false
      #   itms.each do |i|
      #     if i.item.id == @newItem.id
      #
      #       i.quantity += params.require(:chamount).to_f
      #       if i.item.remaining_quantity < 0
      #         am = i.item.remaining_quantity.abs
      #         i.item.remaining_quantity = 0
      #         i.quantity -= am
      #         @newItem = @newItem.find_next_usable
      #       else
      #         new_item_in = true
      #       end
      #     end
      #   end
      #   unless new_item_in
      #     @newItem.remaining_quantity -= params.require(:chamount).to_f
      #     itms << OutputOrderItem.new(item: @newItem, output_order: @order, quantity: params.require(:chamount).to_f)
      #   end
      # end
      itms.reverse
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

    def order_params
      params.require(:order).permit(:date, :supplier, :vector, :transportDocument, :purchaseDate)
    end

    def output_params
      @destination = params.require(:code)
      unless params[:order_id].nil? or params[:order_id].to_i == 0
        @order = OutputOrder.find(params.require(:order_id))
        if @destination == 'Vehicle'
          if !params['vvehicle_id'].to_i == 0
            @recipient = Vehicle.find(params.require('vvehicle_id').to_i)
          elsif !params['vrecipient'].nil?
            @recipient = Vehicle.find_by_plate(params.require('vrecipient'))
          else
            @recipient = Vehicle.new
          end
        else
          @recipient = @order.destination
        end
      end
      if @order.nil? and params[:code] == 'Worksheet'
        worksheet_params
      end
      if params[:code] == 'Vehicle'
        @receiver = @order.receiver
      end
      # @destination = params.require(:destination)
      # case params.require(:destination).to_sym
      # when :Person
      #   @recipient = params[:recipient].nil?? Person.all.first : Person.find(params.require(:recipient).to_i)
      # when :Office
      #   @recipient = params[:recipient].nil?? Office.all.first : Office.find(params.require(:recipient).to_i)
      # when :Vehicle
      #   # @recipient = (params[:vrecipient].nil? || params[:vrecipient] == '')? Vehicle.find_by_plate((params[:vvehicle_id].nil? || params[:vvehicle_id] == '') ? '': params.require(:vvehicle_id)).first : Vehicle.find_by_plate(params.require(:vrecipient)).first
      #   if params[:vrecipient] == '' and params[:vvehicle_id] == ''
      #     @recipient = Vehicle.new
      #   else
      #     @recipient = (params[:vrecipient].nil? || params[:vrecipient] == '')? Vehicle.find_by_plate((params[:vvehicle_id].nil? || params[:vvehicle_id] == '') ? '': params.require(:vvehicle_id)) : Vehicle.find_by_plate(params.require(:vrecipient))#.first
      #   end
      #   if params[:precipient] == '' or params[:precipient].nil?
      #     @receiver = Person.new
      #   else
      #     @receiver = Person.find(params.require(:precipient).to_i)
      #   end
      # when :Worksheet
      #   unless params[:recipient].nil? || params[:recipient] == ''
      #     @recipient = Worksheet.findByCode(params.require(:recipient))
      #     if @recipient.nil?
      #       unless params[:vehicle_id].to_i == 0
      #         vehicle = Vehicle.find(params[:vehicle_id].to_i)
      #       end
      #       if vehicle.nil?
      #         vehicle = Vehicle.find_by_plate(params[:vehicle])#.first
      #       end
      #       if vehicle.nil?
      #         vehicle = Vehicle.new
      #       end
      #       @recipient = Worksheet.create(:code => params.require(:recipient).upcase, :vehicle => vehicle)
      #     elsif @recipient.vehicle.nil?
      #       vehicle = Vehicle.find_by_plate(params[:vehicle])#.first
      #       # if vehicle.nil?
      #       #   vehicle = Vehicle.find(params.require(:vehicle_id))
      #       # end
      #       if vehicle.nil?
      #         vehicle = Vehicle.new
      #       end
      #       @recipient.vehicle = vehicle
      #       @recipient.save
      #     end
      #   else
      #     @recipient = Worksheet.new
      #     @recipient.vehicle = Vehicle.new
      #   end
      # end
      unless params[:item].nil?
        @newItem = Item.find(params.require(:item).to_i)
        @newItems = Array.new
        amount = params.require(:chamount).to_f.abs
          av = @newItem.article.actual_availability(@checked_items)
        amount = av if amount > av
        while amount > 0 do
          if amount <= @newItem.remaining_quantity
            @newItem.remaining_quantity -= amount
            @newItems << OutputOrderItem.new(item: @newItem, output_order: @order, quantity: amount)
            amount = 0
          else
            given_quantity = @newItem.remaining_quantity
            amount -= @newItem.remaining_quantity
            @newItem.remaining_quantity = 0
            @newItems << OutputOrderItem.new(item: @newItem, output_order: @order, quantity: given_quantity)

            itms = get_output_items.map! { |oo_itm| oo_itm.item } if itms.nil?
            @newItem = @newItem.find_next_usable(itms)
            itms << @newItem
            if @newItem.nil?
              @error = 'I pezzi disponibili non sono sufficienti.'
              break
            end
          end
        end
        @newItems
      end
    end

    def search_params
      unless params[:search].nil? or params[:search] == ''
        if params[:search].size == 0
          @search = nil
        end
        @search = params.require(:search)
      end
      if params[:from].nil?
        @from = '0'
      else
        @from = params.require(:from)
      end

      unless params[:open_worksheets_filter].nil? or params[:open_worksheets_filter] == ''
        @open_worksheets_filter = params[:open_worksheets_filter] == 'on' ? true : false
      end
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

    def set_order
      @order = Order.find(params[:id])
    end

    def worksheet_params
      ws = Worksheet.find_or_create_by_code(params.require(:recipient)[/(\d*)$/,1])
      @destination = 'Worksheet'
      if ws.nil? and @error.nil?
        @error = "Errori nella ricerca dell'ODL nr. #{params.require(:recipient)[/(\d*)$/,1]}" if @error.nil?
      end
      begin
        @order = OutputOrder.findByRecipient(ws.code,Worksheet).last
        if @order.nil?
          @order = OutputOrder.new(destination: ws)
        end
        @recipient = ws
      rescue Exception => e
        @error = e.message if @error.nil?
      end

      unless @error.nil?
        respond_to do |format|
          format.js { render partial: 'layouts/error'}
        end
        return nil
      end
      ws
      # code = (params[:code].nil? or params[:code] == '') ? params.require(:recipient) : params.require(:code)
      # @destination = 'Worksheet'
      # unless code.nil? or code == ''
      #   if code.index('EWC*').nil?
      #     code.gsub!(/[^\d]/, '')
      #     code = 'EWC*'+code
      #   end
      #   # @recipient = Worksheet.findByCode(code)
      #   @recipient = Worksheet.find_or_create_by_code(code.gsub(/[^\d]/, ''))
      #   # unless params[:vehicle].nil? or params[:vehicle] == ''
      #   #   @recipient.vehicle = Vehicle.find_by_plate(params.require(:vehicle))#.first
      #   #   @recipient.save
      #   # end
      #
      #   unless @recipient.nil?
      #     @order = OutputOrder.findByRecipient(@recipient.code,Worksheet).last
      #   else
      #     @recipient = Worksheet.new(:code => code, :vehicle => Vehicle.new)
      #   end
      #     if @order.nil?
      #       @order = OutputOrder.new
      #     end
      # end
    end
end
