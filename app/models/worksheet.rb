class Worksheet < ApplicationRecord
  resourcify

  belongs_to :vehicle
  has_many :output_orders, -> { where("output_orders.destination_type = 'Worksheet'") }, class_name: 'OutputOrder', foreign_key: :destination_id
  has_many :output_order_items, through: :output_orders
  has_many :items, through: :output_order_items


  scope :filter, ->(search) { joins(:vehicle).where("code LIKE ? OR ",'%'+search+'%') }
  scope :open, -> { where(closingDate: nil) }
  scope :year, ->(year) { where("year(worksheets.created_at) = ?",year) }

  def opened?
    if self.closingDate.nil?
      return true
    else
      return false
    end
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

  def self.upsync_all
    res = get_client.query("select Protocollo, CodiceAutomezzo, Tipo, DataUscitaVeicolo "\
      "from autoodl "\
      "where DataEntrataVeicolo is not null")
    res.each do |odl|
      ws = Worksheet.find_by(code: "EWC*#{odl['Protocollo']}")
      case odl['Tipo']
      when 'A'
          table = 'Altri mezzi'
      when 'T', 'M'
          table = 'Veicoli'
      when 'S', 'R'
          table = 'Rimorchi1'
      end

      vehicle = Vehicle.get_by_reference(table,odl['CodiceAutomezzo'])
      if ws.nil?
        Worksheet.create(code: "EWC*#{odl['Protocollo']}", vehicle: vehicle)
      else
        ws.update(code: "EWC*#{odl['Protocollo']}", vehicle: vehicle, closingDate: odl['DataUscitaVeicolo'].nil?? nil : Date.parse(odl['DataUscitaVeicolo']))
      end
    end
  end

  def self.findByCode code
    Worksheet.where(code: code).first
  end

  def self.filter(search)
    Worksheet.find_by_sql("SELECT DISTINCT w.* FROM worksheets w LEFT JOIN vehicle_informations i ON w.vehicle_id = i.vehicle_id WHERE w.code LIKE '%#{search}%' OR i.information LIKE '%#{search}%'")
  end

  private

  def self.special_logger
    @@special_logger ||= Logger.new("#{Rails.root}/log/worksheets.log")
  end

  def self.get_client
    Mysql2::Client.new username: ENV['RAILS_EUROS_USER'], password: ENV['RAILS_EUROS_PASS'], host: ENV['RAILS_EUROS_HOST'], port: ENV['RAILS_EUROS_PORT'], database: ENV['RAILS_EUROS_DB']
  end

end
