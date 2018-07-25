class CodesController < ApplicationController

  before_action :authenticate_user!
  before_action :special_logger
  protect_from_forgery except: [:carwash_check,:carwash_close,:carwash_authorize]
  skip_before_action :authenticate_user!, :only => [:carwash_check,:carwash_close,:carwash_authorize]

  rescue_from ApplicationController, :with => :error
  # before_action :get_person, only: [:new_carwash_driver_code,:update_carwash_driver_code]
  before_action :get_action, only: [:update_carwash_driver_code,:update_carwash_vehicle_code,:update_carwash_special_code]
  before_action :get_driver_code, only: [:new_carwash_driver_code,:update_carwash_driver_code]
  before_action :get_vehicle_code, only: [:new_carwash_vehicle_code,:update_carwash_vehicle_code]

  # autocomplete :person, :surname, extra_data: [:name], full: true, :id_element => '#person_id', display_value: :complete_name
  autocomplete :vehicle_information, :information, full: true, :id_element => '#vehicle_id', display_value: :information

  def index

  end

  def autocomplete_person_surname
    render :json => Person.filter(params.permit(:term)[:term]).map{ |p| { id: p.id.to_s, label: p.list_name, value: p.list_name, name: p.name} }
  end

  def carwash_print
    require "prawn/measurement_extensions"

    margins = 15
    card_width = 81
    card_height = 52

    pdf = Prawn::Document.new :filename=>'foo.pdf',
                          :page_size=> "A4",
                          :margin => margins
    codes = Array.new
    unless params[:drivers].nil?
      params.require(:drivers).each do |d|
        code = CarwashDriverCode.find(d.to_i)
        codes << code unless code.nil?
      end
    end
    unless params[:vehicles].nil?
      params.require(:vehicles).each do |d|
        code = CarwashVehicleCode.find(d.to_i)
        codes << code unless code.nil?
      end
    end
    unless params[:special].nil?
      params.require(:special).each do |d|
        code = CarwashSpecialCode.find(d.to_i)
        codes << code unless code.nil?
      end
    end
    y = pdf.cursor
    codes.each_with_index do |c,i|

      if i%2 > 0
        x = card_width.mm+margins.mm
      else
        x = 0
        y -= card_height.mm+margins.mm unless i == 0
      end

      if i%8 == 0 and i != 0
        pdf.start_new_page
        x = 0
        y = pdf.cursor
      end
      pdf.bounding_box([x,y], width: card_width.mm, height: card_height.mm, margin: margins ) do
        pdf.bounding_box([margins,card_height.mm-margins], width: card_width.mm-margins*2, height: card_height.mm-margins*2) do
          pdf.text c.print_owner
          c.generate_barcode
          pdf.image "tmp/cw-code-temp.png", vposition: :center, position: card_width.mm/2-margins
          # pdf.text c.code
        end
        pdf.stroke_bounds
      end

    end
    # photos.each do |p|
    #   file = File.open('tmp.jpg','w')
    #   file.write(p)
    #   file.close
    #   size = FastImage::size('tmp.jpg')
    #
    #   if size[0] > size[1]
    #       image = MiniMagick::Image.new("tmp.jpg")
    #       image.rotate(-90)
    #   end
    #   pdf.image 'tmp.jpg', :fit => [595.28 - margins*2, 841.89 - margins*2]
    # end
    respond_to do |format|
      format.pdf do
        send_data pdf.render, filename: "tessere_lavaggio_#{Date.current.strftime('%Y%m%d')}.pdf",
        type: "application/pdf"
      end
    end
  end

  def carwash_authorize
    m = params.require(:codes).match(/codici=(.*)?&pista=(.*)?/)
    row = m[2]
    codes = m[1].split(',')
    vehicles = Array.new
    types = Array.new
    driver = nil
    special = nil
    already_washed = Array.new
    codes.uniq.each do |c|
      code = CarwashDriverCode.findByCode(c).first || CarwashVehicleCode.findByCode(c).first || CarwashSpecialCode.findByCode(c).first

      if !code.disabled && code.is_a?(CarwashDriverCode)
        driver = code.person
      elsif !code.disabled && code.is_a?(CarwashSpecialCode)
        special = code
      elsif !code.disabled && code.is_a?(CarwashVehicleCode)
        vehicles << code.vehicle unless Vehicle.carwash_codes[code.vehicle.carwash_code] == 0 # and code.vehicle.vehicle_type.carwash_type == 0
      end
    end
    if special.nil?
      vehicles.each do |v|
        already_washed << v if v.just_washed?
      end
    end
    vehicles -= already_washed
    unless (driver.nil? and special.nil?) or ((vehicles.size > 2 or vehicles.size < 1) and special.nil?)
      cwu = CarwashUsage.create(session_id: CarwashUsage.generate_session, person: driver, vehicle_1: vehicles[0], vehicle_2: vehicles[1], carwash_special_code: special, row: row, starting_time: DateTime.now)
      response = "#{cwu.session_id}"
      unless cwu.carwash_special_code.nil?
        response += ",#{cwu.carwash_special_code.carwash_code}"
      else
        response += ",#{Vehicle.carwash_codes[cwu.vehicle_1.carwash_code]}" unless cwu.vehicle_1.nil?
        response += ",#{Vehicle.carwash_codes[cwu.vehicle_2.carwash_code]}" unless cwu.vehicle_2.nil?
      end
      @@special_logger.info("Authorize -> row: #{row} || codes: #{codes.inspect}  ||| #{params.inspect}")
    else
      @@special_logger.error("Authorize -> row: #{row} || special: #{special.inspect} || driver: #{driver.inspect} || vehicles: #{vehicles.inspect} || codes: #{codes.inspect}  ||| #{params.inspect}")
      response = 0
    end

    render :html => response


  end

  def carwash_close
    cwu = CarwashUsage.find_by(:session_id => params.require(:sessionid))
   @@special_logger.info("Close -> #{cwu.inspect} ||| #{params.inspect}")
    if cwu.nil? or !cwu.ending_time.nil?
      render :json => 0
    else
      cwu.update(:ending_time => DateTime.now)
      render :json => 1
    end
  end

  def carwash_force_close
    begin
      cwu = CarwashUsage.find(params.require(:id))
      @@special_logger.info("Close -> #{cwu.inspect} ||| #{params.inspect} ||| #{current_user.person.complete_name}")
      cwu.update(:ending_time => DateTime.now)
      respond_to do |format|
        format.js { render partial: 'carwash/index_js' }
      end
    rescue Exception => e
      @error = e.message+"\n\n#{e.backtrace}"
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def carwash_check
    code = CarwashDriverCode.findByCode(params.permit(:code)[:code]).first || CarwashVehicleCode.findByCode(params.permit(:code)[:code]).first || CarwashSpecialCode.findByCode(params.permit(:code)[:code]).first
    @@special_logger.info("Check -> #{code.inspect} ||| #{params.inspect}")
    if (code.class == CarwashVehicleCode)
      if code.vehicle.carwash_code == 'N/D'
        no_go = true
      end
    end
    if(code.nil? || no_go || code.disabled)
      render :json => 0
    else
      render :json => 1
    end
  end

  def new_carwash_driver_code
    unless @person.nil? || !@code.nil?
      CarwashDriverCode.create(code: 'A'+SecureRandom.hex(2).upcase, person: @person)
    end
    # if @code.nil?
    #   CarwashDriverCode.create(code: params.require(:carwash_driver_code).permit(:code)[:code].upcase)
    #   # @msg = 'Codice creato.'
    # else
    #   # @msg = 'Codice esistente.'
    # end
    respond_to do |format|
      format.js { render :partial => 'codes/driver_codes_js' }
    end
  end

  def update_carwash_driver_code
    unless @code.nil?
      case @action
      when :regenerate
        @code.regenerate
      when :disable
        @code.update(disabled: true)
      when :enable
        @code.update(disabled: false)
      end
      # @msg = 'Codice creato.'
    else
      # @msg = 'Codice esistente.'
    end
    respond_to do |format|
      format.js { render :partial => 'codes/driver_codes_js' }
    end
  end

  def new_carwash_special_code
    unless params[:carwash_special_code].nil?
      p = params.require(:carwash_special_code).permit([:label, :carwash_code])
      unless p[:label] == '' or p[:carwash_code] == ''
        CarwashSpecialCode.createUnique(p[:label], p[:carwash_code].to_i)
      end
    end
    # if @code.nil?
    #   CarwashDriverCode.create(code: params.require(:carwash_driver_code).permit(:code)[:code].upcase)
    #   # @msg = 'Codice creato.'
    # else
    #   # @msg = 'Codice esistente.'
    # end
    respond_to do |format|
      format.js { render :partial => 'codes/special_codes_js' }
    end
  end

  def update_carwash_special_code
    @code = CarwashSpecialCode.find(params.require(:id)) unless params[:id].nil?
    unless @code.nil?
      case @action
      when :regenerate
        @code.regenerate
      when :disable
        @code.update(disabled: true)
      when :enable
        @code.update(disabled: false)
      end
      # @msg = 'Codice creato.'
    else
      # @msg = 'Codice esistente.'
    end
    respond_to do |format|
      format.js { render :partial => 'codes/special_codes_js' }
    end
  end

  def new_carwash_vehicle_code
    unless @vehicle.nil? or !@code.nil?
      if @vehicle.class == Vehicle
        CarwashVehicleCode.create(code: 'M'+SecureRandom.hex(2).upcase, vehicle: @vehicle)
      else
        # CarwashVehicleCode.create(code: 'M'+SecureRandom.hex(2).upcase, external_vehicle: @vehicle)
      end
      # @msg = 'Codice creato.'
    else
      # @msg = 'Codice esistente.'
    end
    respond_to do |format|
      format.js { render :partial => 'codes/vehicle_codes_js' }
    end
  end

  def update_carwash_vehicle_code
    unless @code.nil?
      case @action
      when :regenerate
        @code.regenerate
      when :disable
        @code.update(disabled: true)
      when :enable
        @code.update(disabled: false)
      end
      # @msg = 'Codice creato.'
    else
      # @msg = 'Codice esistente.'
    end
    # unless @code.nil?
    #   case @action
    #   when :update
    #     @code.update(vehicle: get_vehicle)
    #   when :clear
    #     @code.update(vehicle: nil)
    #   when :delete
    #     @code.destroy
    #   when :print
    #     @code.print
    #   end
    #   # @msg = 'Codice creato.'
    # else
    #   # @msg = 'Codice esistente.'
    # end
    respond_to do |format|
      format.js { render :partial => 'codes/vehicle_codes_js' }
    end
  end

  def error e
    @error = e.message
    respond_to do |format|
      format.js { render :partial => 'layouts/error' }
    end
  end

  private

  def special_logger
    @@special_logger ||= Logger.new("#{Rails.root}/log/carwash.log")
  end

  def get_driver_code

    if(params[:id].nil?)
      get_person
      unless @person.nil?
        @code = CarwashDriverCode.where(person: @person).first
      end
    else
      @code = CarwashDriverCode.find(params.require(:id).to_i)
    end
  end

  def get_vehicle_code
    if(params[:id].nil?)
      get_vehicle
      unless @vehicle.nil?
        @code = CarwashVehicleCode.where(vehicle: @vehicle).first
      end
    else
      @code = CarwashVehicleCode.find(params.require(:id).to_i)
    end
    # if(params[:id].nil?)
    #   @params = params.require(:carwash_vehicle_code).permit(:code,:vehicle)
    #   @code = CarwashVehicleCode.findByCode(@params[:code].upcase).first
    # else
    #   @params = params.require(:carwash_vehicle_code).permit(:vehicle)
    #   @code = CarwashVehicleCode.find(params.require(:id).to_i)
    # end
    # case params.permit(:commit)[:commit]
    # when 'M'
    #   @action = :update
    # when 'C'
    #   @action = :clear
    # when 'X'
    #   @action = :delete
    # when 'Stampa'
    #   @action = :print
    # end
  end

  def get_action
    case params.permit(:commit)[:commit]
      when 'Rigenera'
        @action = :regenerate
      when 'Disabilita'
        @action = :disable
      when 'Abilita'
        @action = :enable
    end

  end

  def get_person
    @person = Person.find_by_complete_name(params.require(:carwash_driver_code).permit(:person)[:person])
  end

  def get_vehicle
    @vehicle = Vehicle.find_by_plate(params.require(:carwash_vehicle_code).permit(:plate)[:plate]).first
    @vehicle = ExternalVehicle.find_by(plate: params.require(:carwash_vehicle_code).permit(:plate)[:plate]) if @vehicle.nil?
  end


end
