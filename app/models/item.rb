class Item < ApplicationRecord
  resourcify
  include CharsetUtility
  include BarcodeUtility
  require 'barby/outputter/cairo_outputter'
  # require 'barby/outputter/png_outputter'
  require 'barby/barcode/ean_13'
  require 'barby/barcode/ean_8'

  after_create :generateBarcode

  belongs_to :article
  belongs_to :transportDocument
  has_many :item_relations
  has_many :output_order_items
  has_many :output_orders, through: :output_order_items
  belongs_to :position_code

  scope :available_items, -> { where('items.id not in (select item_id from output_order_items)')}
  scope :barcode, ->(barcode) { joins(:article).where("items.barcode = '#{barcode}' OR articles.barcode = '#{barcode}'") }
  # scope :available_items, -> { joins(:item_relations).where('item_relations.office_id' => nil).where('item_relations.vehicle_id' => nil).where('item_relations.person_id' => nil).where('item_relations.worksheet_id' => nil)}
  scope :unassigned, -> { left_outer_joins(:output_order_items).where("output_order_items.output_order_id IS NULL") }
  scope :limited, -> { limit(100) }
  scope :article, ->(article) { where(:article => article) }
  scope :filter, ->(search) { joins(:position_code).joins(:article).joins(:article => :manufacturer).where("items.serial LIKE '%#{search}%' OR items.barcode LIKE '%#{search}%' OR articles.barcode LIKE '%#{search}%' OR articles.description LIKE '%#{search}%' OR companies.name LIKE '%#{search}%' OR articles.name LIKE '%#{search}%' OR articles.manufacturerCode LIKE '%#{search}%' OR (#{PositionCode.getQueryFromCode(search)})")}
  scope :lastCreatedOrder, -> { reorder(created_at: :desc) }
  scope :firstCreatedOrder, -> { reorder(created_at: :asc) }
  scope :unpositioned, -> { where(:position_code => PositionCode.findByCode('P0 #0 0-@')) }
  # scope :unassigned, -> {  }
  enum state: [:nuovo,:usato,:rigenerato,:ricoperto,:riscolpito,:preparato,:danneggiato,:smaltimento]

  @amount = 1
  @actualItems = Array.new

  def showLabel
    self.article.complete_name+(self.serial.to_s == '' ? '' : ', Seriale/matricola: '+self.serial)+', posizione: '+self.position_code.code
  end

  # def self.available_items
  #   Item.all.map { |i| i.available? }
  # end
  def actualPrice
    self.price.to_f * ((100 - self.discount.to_f) / 100)
  end

  def complete_price
    price = self.actualPrice.to_s+' €'
    if (self.discount.to_i > 0)
       price += ' ('+self.price.to_s+' -'+self.discount.to_s+'%'+')'
    end
    price
  end

  def complete_name
    self.article.complete_name
  end

  def complete_barcode_name
    self.actualBarcode+' - '+self.article.complete_name
  end



  def self.firstBarcode(barcode)
    Item.barcode(barcode)
  end

  def self.firstGroupByArticle(search_params,gonerList)
    art = Hash.new
    Item.unassigned.available_items.filter(search_params).lastCreatedOrder.each do |it|
      flag = true
      gonerList.each do |gl|
        if it.id == gl.id
          flag = false
          break
        end
      end
      if flag
        art[it.article.id.to_s+it.state] = it
      end
    end
    return art
  end

  def amount
    @amount
  end

  def setAmount q
    @amount = q
  end

  def actualItems
    @actualItems
  end

  def setActualItems
    @actualItems = Array.new
  end

  def addActualItems id
    @actualItems << id
  end

  def last_position
    self.item_relations.sort_by(&:since).last
  end

  def last_order
    self.output_orders.sort_by(&:created_at).last
  end

  def actual_position
    unless self.last_order.nil?
      @od = " (Ordine nr. #{self.last_order.id})"
    else
      @od = ''
    end
    if self.item_relations.size > 0
      relation = self.last_position
      unless relation.office.nil?
        return relation.office.name+@od
      end
      unless relation.vehicle.nil?
        return relation.vehicle.plate+@od
      end
      unless relation.person.nil?
        return relation.person.complete_name+@od
      end
      unless relation.worksheet.nil?
        return relation.worksheet.complete_name+@od
      end
      return self.position_code.code+@od
    else
      return nil
    end
  end

  # def position
  #   relation = self.item_relations.sort_by(&:since).last
  #   unless relation.office.nil?
  #     return relation.office
  #   end
  #   unless relation.vehicle.nil?
  #     return relation.vehicle
  #   end
  #   unless relation.person.nil?
  #     return relation.person
  #   end
  #   unless relation.worksheet.nil?
  #     return relation.worksheet
  #   end
  #   return nil
  # end

  def take_back
    self.last_position.delete
  end

  def available?
    if self.actual_position.nil? && self.output_orders.size == 0
      true
    else
      false
    end
  end

  def generateBarcode
    # unless self.serial.nil? || self.serial == ''
    if self.id.nil?
      self.save
    end
    if self.barcode.nil? && (self.article.barcode.nil? || self.article.barcode == '' || !self.serial.nil? || !self.serial != '')

      self.barcode = self.id.to_s(16).rjust(9,'0')
      self.save
      self.setBarcodeImage
      # self.printLabel
    end
  end

  def setBarcodeImage
    unless self.actualBarcode == ''
      if barcode = checkBarcode(self.actualBarcode)
        @blob = Barby::CairoOutputter.new(barcode).to_png #Raw PNG data
        File.write("public/images/#{self.barcode}.png", @blob)
      else
        self.barcode = 'Codice non valido'
      end
    end
  end

  def actualBarcode

    if self.serial.to_s.size == 0
      self.article.barcode
    else
      self.barcode
    end
  end

  # def currentBarcode
  #   if self.serial != '' || self.article.barcode.nil?
  #     self.barcode
  #   else
  #     self.article.barcode
  #   end
  # end

  def printLabel
    if self.actualBarcode.nil? or self.actualBarcode == ''
      self.generateBarcode
    end
    label = Zebra::Epl::Label.new(
      :width         => 385,
      :length        => 180,
      :print_speed   => 3,
      :print_density => 6
    )
    # box = Zebra::Epl::Box.new :position => [0, 0], :end_position => [385, 180], :line_thickness => 2
    # label << box
    name = self.article.complete_name.tr('"',"''")
    text  = Zebra::Epl::Text.new :data => self.expiringDate?? 'Sc. '+self.expiringDate.strftime('%d/%m/%Y') : '', :position => [10, 10], :font => Zebra::Epl::Font::SIZE_3
    label << text
    # text  = Zebra::Epl::Text.new :data => self.position_code.code, :position => [220, 10], :font => Zebra::Epl::Font::SIZE_2
    # label << text
    if name.size > 32
      text  = Zebra::Epl::Text.new :data => name[0..31], :position => [10, 40], :font => Zebra::Epl::Font::SIZE_2
      label << text
      text  = Zebra::Epl::Text.new :data => name[32..-1], :position => [10, 60], :font => Zebra::Epl::Font::SIZE_2
      label << text
    else
      text  = Zebra::Epl::Text.new :data => name, :position => [10, 40], :font => Zebra::Epl::Font::SIZE_2
      label << text
    end
    # text  = Zebra::Epl::Text.new :data => self.article.complete_name, :position => [10, 40], :font => Zebra::Epl::Font::SIZE_2
    # label << text
    text  = Zebra::Epl::Text.new :data => (self.serial.nil? || self.serial == '') ? '' : 'Mat. '+self.serial, :position => [10, 80], :font => Zebra::Epl::Font::SIZE_4
    label << text
    barcode = Zebra::Epl::Barcode.new(
      :data                      => self.actualBarcode,
      :position                  => [10, 120],
      :height                    => 30,
      :print_human_readable_code => true,
      :narrow_bar_width          => 2,
      :wide_bar_width            => 4,
      :type                      => Zebra::Epl::BarcodeType::CODE_128_AUTO
    )
    label << barcode
    print_job = Zebra::PrintJob.new "zebra"
    print_job.print label
  end
  # def setBarcode
  #   serial = self.serial?? 'MAT'+self.serial : 'DATA'+Time.now.to_formatted_s(:number)
  #   self.barcode = SecureRandom.base58(9)
  #   self.save
  #   self.generateBarcode
  # end
  #
  # def generateBarcode
  #   if bc = checkBarcode(self.barcode,'Code39')
  #     @blob = Barby::CairoOutputter.new(bc).to_png({height: 40}) #Raw PNG data
  #     File.write("public/images/#{self.barcode}.png", @blob)
  #   end
  # end
end
