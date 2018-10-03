class Worksheet < ApplicationRecord
  resourcify
  include ErrorHelper
  include BarcodeUtility
  require 'barby/outputter/cairo_outputter'
  # require 'barby/outputter/png_outputter'
  require 'barby/barcode/ean_13'
  require 'barby/barcode/ean_8'
  belongs_to :vehicle
  has_many :output_orders, -> { where("output_orders.destination_type = 'Worksheet'") }, class_name: 'OutputOrder', foreign_key: :destination_id
  has_many :output_order_items, through: :output_orders
  has_many :items, through: :output_order_items

  has_many :worksheet_operations
  has_many :workshop_operations
  has_one :vehicle_check_session

  belongs_to :vehicle, polymorphic:true

  scope :filter, ->(search) { joins(:vehicle).where("code LIKE ? OR ",'%'+search+'%') }
  scope :open, -> { where(exit_time: nil, suspended: false) }
  scope :closed, -> { where("exit_time is not null") }

  # scope :incoming, ->(search,opened) { where(exit_time: nil, suspended: false, station: "workshop", closed: false).where(opened ? '1' : 'opening_date is not null').where(search.nil?? '1' : "(case worksheets.vehicle_type when 'Vehicle' then worksheets.vehicle_id in (select vehicle_informations.vehicle_id from vehicle_informations where information like '%#{search}%') when 'ExternalVehicle' then worksheets.vehicle_id in (select external_vehicles.id from external_vehicles where external_vehicles.plate like '%#{search}%') end) or code like '%#{search}%'") }
  scope :year, ->(year) { where("year(worksheets.created_at) = ?",year) }

  def check_operations
    WorkshopOperation.where(worksheet: self, myofficina_reference: nil)
  end

  def hours
    (self.real_duration/3600).round(1)
  end

  def set_hours
    self.update(real_duration: self.operations.map{ |op| op.real_duration }.inject(0,:+))
  end

  def self.on_processing
    odl = EurowinController::closed_worksheets
    Worksheet.find_by_sql("select worksheets.* from worksheets where "\
            "(exit_time is null and closingDate is null and suspended = 0 and opening_date is not null "\
            "and code not in (#{odl.map { |odl| "'EWC*#{odl['Protocollo']}'"}.join(',')})) "\
            "or id in (select worksheet_id from workshop_operations where ending_time is null) order by opening_date")
  end

  def hour_unit_price
    30
  end

  def material_unit_price
    5
  end

  def damage_type
    EurowinController::get_odl_tipo_danno(self,true)
  end

  def opened?
    if self.closingDate.nil?
      return true
    else
      return false
    end
  end

  def close_related_operations
    if self.exit_time.nil?
      ending = self.closingDate
    else
      ending = self.exit_time
    end
    self.operations.each{ |wo| wo.update(ending_time: ending)} unless ending.nil?
  end

  #get ew worksheets and update or create ws
  def self.get_incoming(search)
    wks = Array.new
    # sat = Vehicle.get_satellite_data
    EurowinController::get_worksheets({opened: :opened, search: search, search_fields: [:plate,:operator]}).each do |odl|
      ws = Worksheet.find_or_create_by_code(odl['Protocollo'])

      if ws.nil?
        special_logger.error("EW retrieval error: \n\n#{odl.inspect}\n\n")
      else
        wks << {ws: ws, plate: odl['Targa'].tr(' .*',''), vehicle: ws.vehicle_id, no_satellite: (Time.now - ws.vehicle.last_gps.to_i > 7.days)}
      end
    end

    wks.sort_by{|ws| ws[:plate]}
  end
  #filter operator from incoming worksheets from eurowin
  def self.incoming_operator(search)
    # ewc = EurowinController::get_ew_client
  end

  #filter plate and operator's name from incoming worksheets
  def self.incoming_plate_operator_filter(search)
    Worksheet.incoming(search,true) + Worksheet.incoming_operator(search)
  end

  def real_duration_label
    "#{(self.real_duration.to_i/3600).floor.to_s.rjust(2,'0')}:#{((self.real_duration.to_i/60)%60).floor.to_s.rjust(2,'0')}:#{(self.real_duration.to_i%60).floor.to_s.rjust(2,'0')}"
  end

  def notifications(mod = :opened)
    n = EurowinController::get_notifications_from_odl(self.number,mod)
    if n.nil?
      n = []
    end
    n
  end

  def ew_worksheet
    EurowinController::get_worksheet(self.number)
  end

  def ew_operator
    EurowinController::get_operator_from_odl(self.number)
  end

  def spare_items
    si = Hash.new
    self.output_order_items.each do |ooi|
      item = ooi.item
      article = item.article
      if si["#{article.id}-#{item.serial}"].nil?
        si["#{article.id}-#{item.serial}"] = { quantity: ooi.quantity, complete_name: article.complete_name, serial: item.serial}
      else
        si["#{article.id}-#{item.serial}"][:quantity] += ooi.quantity
      end
    end
    si
  end

  def number
    self.code[/EWC\*(.*)/,1]
  end

  def code_number
    self.code.tr 'EWC*' ''
  end

  def complete_name
    unless self.code.nil? or self.vehicle.nil?
      self.code+' (Targa: '+self.vehicle.plate+')'
    else
      'Nuova scheda di lavoro'
    end
  end

  def total_label
    self.complete_name+': '+("%.2f" % self.total_price)+"€"
  end

  def items_price
    self.items.map{ |i| i.actual_price }.inject(0,:+)
  end

  def items_price_label
    "Valore ricambi: #{"%.2f" % items_price}€"
  end

  def actual_hours(seconds = false)
    if seconds
      if self.hours == 0
        self.real_duration
      else
        (self.hours.to_f * 3600).to_i
      end
    else
      if self.hours == 0
        self.real_duration.to_f/3600
      else
        self.hours.to_f
      end
    end
  end

  def actual_hours_label(complete = false)
    if complete
      "#{(self.actual_hours(true)/3600).floor.to_s}:#{((self.actual_hours(true)/60)%60).floor.to_s.rjust(2,'0')}:#{(self.actual_hours(true)%60).floor.to_s.rjust(2,'0')}"
    else
      "#{(self.actual_hours(true)/3600).floor.to_s}:#{((self.actual_hours(true)/60)%60).floor.to_s.rjust(2,'0')}"
    end
  end

  def operations(operator = nil)
    if operator.nil?
      WorkshopOperation.where(worksheet: self)
    else
      WorkshopOperation.where(worksheet: self, user: operator)
    end
  end

  def hours_price
    self.actual_hours.to_f * self.hour_unit_price
  end

  def hours_price_label
    "Ore di lavoro: #{self.actual_hours_label} (#{"%.2f" % self.hour_unit_price}€)"
  end

  def hours_complete_price
    "#{"%.2f" % self.hours_price} € \n(#{self.actual_hours_label} * #{"%.2f" % self.hour_unit_price}€)".tr('.',',')
  end

  def materials_price
    self.actual_hours.to_f * self.material_unit_price
  end

  def materials_price_label
    "Materiali di consumo: #{"%.2f" % self.materials_price}€"
  end

  def materials_complete_price
    "#{"%.2f" % self.materials_price} € \n(#{self.actual_hours_label} * #{"%.2f" % self.material_unit_price}€)".tr('.',',')
  end

  def total_price
    self.items_price+self.hours_price+self.materials_price
  end

  def toggle_closure
    if self.closingDate.nil?
      self.update(closingDate: Date.current)
    else
      self.update(closingDate: nil)
    end
    OutputOrder.where("destination_type = 'Worksheet' and destination_id = ?",self.id).each do |oo|
      oo.update(:processed => !self.opened?)
    end
  end

  def self.find_or_create_by_code(protocol)
    protocol = protocol.to_s[/(EWC\*)?([0-9]+).*/,2]
    ws = Worksheet.find_by(code: "EWC*#{protocol}")

    if ws.nil?
      ewc = EurowinController::get_ew_client
      res = ewc.query("select Protocollo, CodiceAutomezzo, automezzi.Tipo, FlagSchedaChiusa, "\
        "DataUscitaVeicolo, DataEntrataVeicolo, autoodl.Note, FlagProgrammazioneSospesa, CodiceAnagrafico, "\
        "(select descrizione from tabdesc where codice = autoodl.codicetipodanno and gruppo = 'AUTOTIPD') as TipoDanno "\
        "from autoodl "\
        "inner join automezzi on autoodl.CodiceAutomezzo = automezzi.Codice "\
        "where Protocollo = #{protocol} limit 1")
      ewc.close

      if res.count > 0
        ws = Worksheet.upsync_ws(res.first)
      end
    end
    ws
  end

  def self.upsync_ws(odl)
    ws = Worksheet.find_by(code: "EWC*#{odl['Protocollo']}")
    case odl['Tipo']
    when 'A'
        table = 'Altri mezzi'
    when 'T', 'M'
        table = 'Veicoli'
    when 'S', 'R', ''
        table = 'Rimorchi1'
    end
    begin
  	  if odl['Tipo'] != 'C' and !table.nil?
  		    vehicle = Vehicle.get_or_create_by_reference(table,odl['CodiceAutomezzo'])
  	  else
  		    vehicle = Vehicle.new
  	  end
      @error = "Impossibile trovare veicolo con id Access #{odl['CodiceAutomezzo']} (tabella #{table})" if vehicle.nil?
      # raise "Impossibile trovare veicolo con id Access #{odl['CodiceAutomezzo']} (tabella #{table})" if vehicle.nil?
      case odl['CodiceAnagrafico']
      when 'OFF00001' then
        station = 'workshop'
      when 'OFF00047' then
        station = 'carwash'
      else
        station = odl['CodiceAnagrafico'].to_s
      end

      if ws.nil?
        if odl['DataIntervento'].nil?
          closingDate = Date.today
        else
          closingDate = odl['DataIntervento'] < (Date.today - 1.year) ? Date.today : nil
        end
        ws = Worksheet.create(code: "EWC*#{odl['Protocollo']}", vehicle: vehicle, creation_date: odl['DataIntervento'], exit_time: (odl['DataUscitaVeicolo'].nil?? nil : odl['DataUscitaVeicolo']), opening_date: (odl['DataEntrataVeicolo'].nil?? nil : odl['DataEntrataVeicolo']), notes: "#{odl['TipoDanno']} - #{odl['Note']}", suspended: odl['FlagProgrammazioneSospesa'].to_s.upcase == 'TRUE' ? true : false, station: station, closingDate: odl['DataUscitaVeicolo'], closed: odl['FlagSchedaChiusa'].to_s.upcase == 'TRUE' ? true : false)
      else
        if odl['DataIntervento'].nil?
          closingDate = Date.today
        else
          closingDate = odl['DataIntervento'] < (Date.today - 1.year) ? Date.today : ws.closingDate
        end
        ws.update(code: "EWC*#{odl['Protocollo']}", vehicle: vehicle, creation_date: odl['DataIntervento'], exit_time: (odl['DataUscitaVeicolo'].nil?? nil : odl['DataUscitaVeicolo']), opening_date: (odl['DataEntrataVeicolo'].nil?? nil : odl['DataEntrataVeicolo']), notes: "#{odl['TipoDanno']} - #{odl['Note']}", suspended: odl['FlagProgrammazioneSospesa'].to_s.upcase == 'TRUE' ? true : false, station: station, closingDate: odl['DataUscitaVeicolo'], closed: odl['FlagSchedaChiusa'].to_s.upcase == 'TRUE' ? true : false)
      end
      ws
    rescue Exception => e
      # @error = e.message if @error.nil?
      @error =  "#{e.message}\n\n#{e.backtrace}"
    end
    ws
  end

  def self.upsync_all
    ewc = EurowinController::get_ew_client
    res = ewc.query("select Protocollo, CodiceAutomezzo, automezzi.Tipo, FlagSchedaChiusa, "\
      "DataUscitaVeicolo, DataEntrataVeicolo, autoodl.Note, FlagProgrammazioneSospesa, CodiceAnagrafico, "\
      "(select descrizione from tabdesc where codice = autoodl.codicetipodanno and gruppo = 'AUTOTIPD') as TipoDanno "\
      "from autoodl "\
      "inner join automezzi on autoodl.CodiceAutomezzo = automezzi.Codice "\
      "where DataEntrataVeicolo is not null and DataIntervento is not null "\
      "and Anno > #{Date.today.strftime('%Y').to_i - 2} "\
      "and (CodiceAnagrafico = 'OFF00001' or CodiceAnagrafico = 'OFF00047') order by DataEntrataVeicolo desc")
    ewc.close
    @error = ''
    res.each do |odl|
      begin
        odl['FlagProgrammazioneSospesa'] = 'false' if odl['FlagProgrammazioneSospesa'].nil?
        Worksheet.upsync_ws(odl)
      rescue Exception => e
        # raise error
        @error += e.message+"\n\n"
      end
    end
    unless @error == ''
      special_logger.error(@error)

      raise @error
    end
  end

  def close
    # ewc = EurowinController::get_ew
    self.update(closed: true)
  end

  def self.findByCode code
    Worksheet.where(code: code).first
  end

  def self.filter(search)
    Worksheet.find_by_sql("SELECT DISTINCT w.* FROM worksheets w LEFT JOIN vehicle_informations i ON w.vehicle_id = i.vehicle_id WHERE w.code LIKE '%#{search}%' OR i.information LIKE '%#{search}%'")
  end

  def get_pdf_path
    unless File.exists?("#{ENV['RAILS_DOCS_PATH']}/ODL/ODL_#{self.number}.pdf")
      # byebug
      # if self.pdf_path.nil? || self.pdf_path == ''
        path = nil
        list = `find #{ENV['RAILS_WS_PATH']}`
        # list.scan(/.*\/#{self.vehicle.mssql_references.map { |msr| msr.remote_object_id }.join('|')} - .*\/.*-#{self.number}.*\.pdf/) do |line|
        list.scan(/.*-#{self.number}-.*\.pdf/i) do |line|
          path = line
        # end
        if path.nil?
          list.scan(/.*-#{self.number}-.*\.lnk/i) do |line|
            url = "http://10.0.0.101/linkexplode/default.asp?strPath=\\\\10.0.0.99\\Comune\\#{line[/\/mnt\/wshare\/(.*)$/,1].gsub("\/","\\")}"
            path = HTTPI.get(url).raw_body.gsub('Z:\\','/mnt/wshare/').tr('\\','/')
          end
        end
        # self.update(pdf_path: path) unless path.nil?
        `cp #{path.split(' ').join('\ ')} #{ENV['RAILS_DOCS_PATH']}/ODL/ODL_#{self.number}.pdf`

      end
    end
    # self.pdf_path
    return "#{ENV['RAILS_DOCS_PATH']}/ODL/ODL_#{self.number}.pdf"
  end

  def get_pdf
    File.open(self.get_pdf_path,'r')
  end

  def sheet
    vehicle = self.vehicle

    #get various dates
    unless self.opening_date.nil?
      opening_year = self.opening_date.strftime('%Y')
      opening_date = self.opening_date.strftime('%d/%m/%Y')
    end

    unless self.closingDate.nil?
      closing_date = self.closingDate.strftime('%d/%m/%Y')
    end

    unless self.exit_time.nil?
      closing_date = self.exit_time.strftime('%d/%m/%Y')
    end

    unless vehicle.last_washing.nil?
      last_washing_date = vehicle.last_washing.ending_time.strftime('%d/%m/%Y')
    end

    last_check_session = vehicle.last_check_session
    unless last_check_session.nil?
      if last_check_session.finished.nil?
        last_checking_date = last_check_session.date.strftime('%d/%m/%Y')
      else
        last_checking_date = last_check_session.finished.strftime('%d/%m/%Y')
      end
    end

    if !self.damage_type.nil? && (self.damage_type['Descrizione'] == 'MANUTENZIONE' || self.damage_type['Descrizione'] == 'COLLAUDO')
      last_maintainance_date = self.exit_time.strftime('%d/%m/%Y')
    else
      lm = vehicle.last_maintainance
      unless lm.nil?
        if lm.exit_time.nil?
          last_maintainance_date = lm.closingDate.strftime('%d/%m/%Y')
        else
          last_maintainance_date = lm.exit_time.strftime('%d/%m/%Y')
        end
      end
    end

    ld = vehicle.last_driver
    if ld.nil?
      last_driver = nil
    else
      last_driver = vehicle.last_driver.complete_name
    end

    odl = EurowinController::get_worksheet(self.number)

    pdf = Prawn::Document.new

    pdf.image Rails.root.join('app','assets','images','logo.png'),
      fit: [230,50],
      align: :left

    pdf.text_box "ODL nr. #{self.number} - #{self.vehicle.plate}",
      align: :left,
      style: :bold,
      font_size: 20,
      at: [250,705]

    @blob = Barby::CairoOutputter.new(Barby::Code128B.new(self.code)).to_png #Raw PNG data
    File.write("public/images/#{self.code}.png", @blob)
    pdf.image "public/images/#{self.code}.png",
      fit: [230,50],
      align: :right,
      at: [400,725]

    pdf.move_down 20
    if odl.nil?
      vehicle_code = 'ODL mancante'
    else
      vehicle_code = odl['CodiceAutomezzo']
    end
    pdf.table [[pdf.make_table([[pdf.make_cell(content: 'Codice',size: 7)],[pdf.make_cell(content: vehicle_code,size: 13, font_style: :bold)]],width: 40),
            pdf.make_table([[pdf.make_cell(content: 'Mezzo',size: 7)],[pdf.make_cell(content: vehicle.complete_name,size: 13, font_style: :bold)]],width: 250),
            pdf.make_table([[pdf.make_cell(content: 'Anno',size: 7)],[pdf.make_cell(content: opening_year,size: 13, font_style: :bold)]],width: 40),
            pdf.make_table([[pdf.make_cell(content: 'Proprietà',size: 7)],[pdf.make_cell(content: vehicle.property.complete_name,size: 13, font_style: :bold)]],width: 210)]],
      :position => :center,
      :width => 540
      # :column_widths => { 0 => 210, 1 => 223, 2 => 107}

      pdf.table [[pdf.make_table([[pdf.make_cell(content: 'Entrata',size: 7)],[pdf.make_cell(content: opening_date,size: 13, font_style: :bold,height: 25)]],width: 75),
              pdf.make_table([[pdf.make_cell(content: 'Uscita',size: 7)],[pdf.make_cell(content: closing_date,size: 13, font_style: :bold,height: 25)]],width: 75),
              pdf.make_table([[pdf.make_cell(content: 'Km',size: 7)],[pdf.make_cell(content: vehicle.mileage.to_s,size: 13, font_style: :bold,height: 25)]],width: 75),
              pdf.make_table([[pdf.make_cell(content: 'Ultima manutenzione',size: 7)],[pdf.make_cell(content: last_maintainance_date,size: 13, font_style: :bold,height: 25)]],width: 75),
              pdf.make_table([[pdf.make_cell(content: 'Ultimo lavaggio',size: 7)],[pdf.make_cell(content: last_washing_date,size: 13, font_style: :bold,height: 25)]],width: 75),
              pdf.make_table([[pdf.make_cell(content: 'Ultimo autista',size: 7)],[pdf.make_cell(content: last_driver,size: 13, font_style: :bold,height: 25)]],width: 165),]],
        :position => :center,
        :width => 540

    pdf.move_down 20
    pdf.text self.notes
    pdf.move_down 10
    pdf.text 'Segnalazioni:'

    table = [['Nr.','Descrizione','Autista','Esito']]
    # table =
    self.notifications(:all).each do |n|

      if n['FlagRiparato'].to_s.downcase == 'true'
        result = 'Agg.'
      elsif n['FlagSvolto'].to_s.downcase == 'true'
        result = 'Ch.'
      else
        result = 'Ap.'
      end

      ops = Array.new
      WorkshopOperation.where(myofficina_reference: n['Protocollo'].to_i).to_a.each do |wo|
        operator = wo.operator.nil?? 'Operatore mancante' : wo.operator.complete_name
        ops << ["#{wo.name}#{wo.notes.nil? ? '' : "\nNote: #{wo.notes}"}",operator,wo.real_duration_label]
      end
      ops = [['','','']] if ops.count < 1

      pdf.table [[n['Protocollo'],n['DescrizioneSegnalazione'],n['NomeAutista'],result]],
            :column_widths => { 0 => 45, 1 => 365, 2 => 90, 3 => 40}

      pdf.table ops,
            :column_widths => { 0 => 330, 1 => 150, 2 => 60}

      pdf.move_down 5
      # subtable = pdf.make_table([[sub1],[sub2]])
      # table << [n['Protocollo'],subtable]

    end

    ops = Array.new
    self.check_operations.to_a.each do |wo|
      operator = wo.operator.nil?? 'Operatore mancante' : wo.operator.complete_name
      ops << ["#{wo.name}#{wo.notes.nil? ? '' : "\nNote: #{wo.notes}"}",operator,wo.real_duration_label]
    end
    ops = [['','','']] if ops.count < 1

    pdf.table [['','Controlli','','']],
          :column_widths => { 0 => 45, 1 => 365, 2 => 90, 3 => 40}

    pdf.table ops,
          :column_widths => { 0 => 330, 1 => 150, 2 => 60}

    pdf.move_down 5
    # pdf.table table,
    #   # :border_style => :grid,
    #   # :font_size => 11,
    #   :position => :center,
    #   # :column_widths => { 0 => 45, 1 => 365, 2 => 90, 3 => 40},
    #   # :align => { 0 => :right, 1 => :left, 2 => :right, 3 => :left},
    #   :row_colors => ["d2e3ed", "FFFFFF"]

    pdf.move_down 20
    pdf.text 'Materiali:'

    table = [['Articolo','Seriale/matricola','Costo']]
    total = 0.0
    self.output_orders.each do |oo|
      oo.output_order_items.each do |i|
        table << ["#{i.item.article.complete_name} (#{i.quantity}/#{i.item.article.containedAmount})","#{i.item.serial}","#{i.complete_price}"]
      end
      total += oo.total.to_f
    end


    table << ["Ore di lavoro","","#{self.hours_complete_price}"]
    table << ["Materiale di consumo","","#{self.materials_complete_price}"]
    total += self.hours_price
    total += self.materials_price

    table << ["Totale","","#{"%.2f" % total} €".tr('.',',')]

    pdf.table table,
      # :border_style => :grid,
      # :font_size => 11,
      :position => :center,
      :column_widths => { 0 => 210, 1 => 223, 2 => 107},
      # :align => { 0 => :right, 1 => :left, 2 => :right, 3 => :left},
      :row_colors => ["d2e3ed", "FFFFFF"]

      pdf.move_down 20
      pdf.text 'Controlli eseguiti:'

      table = [['Controllo','Valore','Risultato']]
      total = 0.0
      unless self.vehicle_check_session.nil?
        self.vehicle_check_session.vehicle_performed_checks.each do |pc|
          if pc.performed != 0
            vc = pc.vehicle_check
            table << ["#{vc.label}#{pc.notes.nil? ? '' : "\n ** Note: #{pc.notes}"}","#{pc.value}#{vc.measure_unit}","#{pc.result_label}"]
          end
        end
      end

      pdf.table table,
        # :border_style => :grid,
        # :font_size => 11,
        :position => :center,
        :column_widths => { 0 => 340, 1 => 80, 2 => 120},
        # :align => { 0 => :right, 1 => :left, 2 => :right, 3 => :left},
        :row_colors => ["d2e3ed", "FFFFFF"]

    pdf.move_down 20
    pdf.text 'Passaggi:'
    pdf.text self.log.to_s


    pdf.bounding_box([pdf.bounds.right - 50,pdf.bounds.bottom], :width => 60, :height => 20) do
    	count = pdf.page_count
    	pdf.text "Page #{count}"
    end
    pdf
  end

  def print
    pdf = Prawn::Document.new
    pdf.text "ODL nr. #{self.number} - #{self.vehicle.plate}"

    table = [['Articolo','Seriale/matricola','Costo']]
    total = 0.0
    self.output_orders.each do |oo|
      oo.output_order_items.each do |i|
        table << ["#{i.item.article.complete_name} (#{i.quantity}/#{i.item.article.containedAmount})","#{i.item.serial}","#{i.complete_price}"]
      end
      total += oo.total.to_f
    end


    table << ["Ore di lavoro","","#{self.hours_complete_price}"]
    table << ["Materiale di consumo","","#{self.materials_complete_price}"]
    total += self.hours_price
    total += self.materials_price

    table << ["Totale","","#{"%.2f" % total} €".tr('.',',')]

    pdf.move_down 20
    pdf.table table,
      # :border_style => :grid,
      # :font_size => 11,
      :position => :center,
      :column_widths => { 0 => 210, 1 => 223, 2 => 107},
      # :align => { 0 => :right, 1 => :left, 2 => :right, 3 => :left},
      :row_colors => ["d2e3ed", "FFFFFF"]

    pdf.bounding_box([pdf.bounds.right - 50,pdf.bounds.bottom], :width => 60, :height => 20) do
    	count = pdf.page_count
    	pdf.text "Page #{count}"
    end
    pdf
  end

  def self.get_client
    Mysql2::Client.new username: ENV['RAILS_EUROS_USER'], password: ENV['RAILS_EUROS_PASS'], host: ENV['RAILS_EUROS_HOST'], port: ENV['RAILS_EUROS_PORT'], database: ENV['RAILS_EUROS_DB']
  end


  private

  def self.special_logger
    @@special_logger ||= Logger.new("#{Rails.root}/log/worksheets.log")
  end



end
