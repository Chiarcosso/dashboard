class Worksheet < ApplicationRecord
  resourcify
  include ErrorHelper
  belongs_to :vehicle
  has_many :output_orders, -> { where("output_orders.destination_type = 'Worksheet'") }, class_name: 'OutputOrder', foreign_key: :destination_id
  has_many :output_order_items, through: :output_orders
  has_many :items, through: :output_order_items

  has_many :worksheet_operations

  belongs_to :vehicle, polymorphic:true

  scope :filter, ->(search) { joins(:vehicle).where("code LIKE ? OR ",'%'+search+'%') }
  scope :open, -> { where(closingDate: nil, suspended: false) }
  scope :incoming, -> { where(exit_time: nil).where(closingDate: nil).where(suspended: false).where('opening_date is not null').where(station: 'workshop') }
  scope :year, ->(year) { where("year(worksheets.created_at) = ?",year) }

  def opened?
    if self.closingDate.nil?
      return true
    else
      return false
    end
  end

  def real_duration_label
    "#{(self.real_duration.to_i/3600).floor.to_s.rjust(2,'0')}:#{((self.real_duration.to_i/60)%60).floor.to_s.rjust(2,'0')}:#{(self.real_duration.to_i%60).floor.to_s.rjust(2,'0')}"
  end

  def notifications
    EurowinController::get_notifications_from_odl(self.number)
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

  def hours_price
    self.hours.to_f * 30
  end

  def hours_price_label
    "Ore di lavoro: #{self.hours} (#{"%.2f" % self.hours_price}€)"
  end

  def hours_complete_price
    ("%.2f" % self.hours_price.to_s+" € \n("+self.hours.to_s+' ore * 30,00€)').tr('.',',')
  end

  def materials_price
    self.hours.to_f * 5
  end

  def materials_price_label
    "Materiali di consumo: #{"%.2f" % self.materials_price}€"
  end

  def materials_complete_price
    ("%.2f" % self.materials_price.to_s+" € \n("+self.hours.to_s+' ore * 5,00€)').tr('.',',')
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
      res = get_client.query("select Protocollo, CodiceAutomezzo, ifnull(automezzi.Tipo,'S') as Tipo, "\
        "DataIntervento, DataUscitaVeicolo, DataEntrataVeicolo, autoodl.Note, FlagProgrammazioneSospesa, CodiceAnagrafico "\
        "from autoodl "\
        "inner join automezzi on autoodl.CodiceAutomezzo = automezzi.codice "\
        "where Protocollo = #{protocol} limit 1")
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
      # @error = "Impossibile trovare veicolo con id Access #{odl['CodiceAutomezzo']} (tabella #{table})" if vehicle.nil?
      raise "Impossibile trovare veicolo con id Access #{odl['CodiceAutomezzo']} (tabella #{table})" if vehicle.nil?
      case odl['CodiceAnagrafico']
      when 'OFF00001' then
        station = 'workshop'
      when 'OFF00047' then
        station = 'carwash'
      else
        station = odl['CodiceAnagrafico'].to_s
      end
      if ws.nil?
        ws = Worksheet.create(code: "EWC*#{odl['Protocollo']}", vehicle: vehicle, creation_date: odl['DataIntervento'], exit_time: (odl['DataUscitaVeicolo'].nil?? nil : odl['DataUscitaVeicolo']), opening_date: (odl['DataEntrataVeicolo'].nil?? nil : odl['DataEntrataVeicolo']), notes: odl['Note'], suspended: odl['FlagProgrammazioneSospesa'].upcase == 'TRUE' ? true : false, station: station, closingDate: odl['DataIntervento'] < (Date.today - 1.year) ? DateTime.now : nil)
      else
        ws.update(code: "EWC*#{odl['Protocollo']}", vehicle: vehicle, creation_date: odl['DataIntervento'], exit_time: (odl['DataUscitaVeicolo'].nil?? nil : odl['DataUscitaVeicolo']), opening_date: (odl['DataEntrataVeicolo'].nil?? nil : odl['DataEntrataVeicolo']), notes: odl['Note'], suspended: odl['FlagProgrammazioneSospesa'].upcase == 'TRUE' ? true : false, station: station, closingDate: odl['DataIntervento'] < (Date.today - 1.year) ? Date.today : ws.closingDate)
      end
    rescue Exception => e
      # @error = e.message if @error.nil?
      raise "#{e.message}\n\n#{e.backtrace}"
    end
    ws
  end

  def self.upsync_all
    res = get_client.query("select Protocollo, CodiceAutomezzo, automezzi.Tipo, "\
      "DataUscitaVeicolo, DataEntrataVeicolo, autoodl.Note, FlagProgrammazioneSospesa, CodiceAnagrafico "\
      "from autoodl "\
      "inner join automezzi on autoodl.CodiceAutomezzo = automezzi.Codice "\
      "where DataEntrataVeicolo is not null and (CodiceAnagrafico = 'OFF00001' or CodiceAnagrafico = 'OFF00047') order by DataEntrataVeicolo desc")

    @error = ''
    res.each do |odl|
      begin
        odl['FlagProgrammazioneSospesa'] = 'false' if odl['FlagProgrammazioneSospesa'].nil?
        Worksheet.upsync_ws(odl)
      rescue Exception => e
        @error += e.message+"\n\n"
      end
    end
    unless @error == ''
      # special_logger(@error)
      # raise @error
    end
  end

  def self.findByCode code
    Worksheet.where(code: code).first
  end

  def self.filter(search)
    Worksheet.find_by_sql("SELECT DISTINCT w.* FROM worksheets w LEFT JOIN vehicle_informations i ON w.vehicle_id = i.vehicle_id WHERE w.code LIKE '%#{search}%' OR i.information LIKE '%#{search}%'")
  end

  def get_pdf
    path = nil
    list = `find #{ENV['RAILS_WS_PATH']}`
    # list.scan(/.*\/#{self.vehicle.mssql_references.map { |msr| msr.remote_object_id }.join('|')} - .*\/.*-#{self.number}.*\.pdf/) do |line|
    list.scan(/.*-#{self.number}-.*\.pdf/i) do |line|
      path = line
    end
    if path.nil?
      list.scan(/.*-#{self.number}-.*\.lnk/i) do |line|
        path = line
      end
      if path.nil?
        raise "File non trovato."
      else
        raise "Il file è un collegamento."
      end
    end
    File.open(path,'r')
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
