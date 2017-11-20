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

  # scope :available_items, -> { where('items.id not in (select item_id from output_order_items) or items.remaining_quantity > 0').order(:remaining_quantity => :asc, :created_at => :asc)}
  scope :available_items, -> { where('items.remaining_quantity > 0').order(:remaining_quantity => :asc, :created_at => :asc)}
  scope :in_storage, -> { where('items.id not in (?)',Office.mobile_workshops(1).items.map { |i| i.id }+Office.mobile_workshops(2).items.map { |i| i.id }) }
  # scope :group_by_article, -> { group(:article_id, :serial) }
  scope :barcode, ->(barcode) { joins(:article).where("items.barcode = ? OR articles.barcode = ?", barcode, barcode) }
  scope :tyres, -> { joins(:article).joins('inner join article_categorizations on articles.id = article_categorizations.category_id').joins('inner join article_categories on article_categorizations.article_id = article_categories.id').where('article_categories.name like \'%gomme%\'') }
  scope :notyres, -> { joins(:article).joins('left join article_categorizations on articles.id = article_categorizations.category_id').joins('left join article_categories on article_categorizations.article_id = article_categories.id').where('article_categories.name not like \'%gomme%\' or article_categories.name is null') }
  # scope :available_items, -> { joins(:item_relations).where('item_relations.office_id' => nil).where('item_relations.vehicle_id' => nil).where('item_relations.person_id' => nil).where('item_relations.worksheet_id' => nil)}
  scope :unassigned, -> { left_outer_joins(:output_order_items).where("output_order_items.output_order_id IS NULL or items.remaining_quantity > 0") }
  scope :assigned, -> { left_outer_joins(:output_order_items).where("output_order_items.output_order_id IS NOT NULL and items.remaining_quantity = 0") }
  scope :assigned_to, ->(what) { joins('inner join output_order_items i on items.id = i.item_id').joins('inner join output_orders on output_orders.id = i.output_order_id').where('output_orders.destination_type = \'Office\' and output_orders.destination_id = ?',what) }
  scope :limited, -> { limit(100) }
  scope :article, ->(article) { where(:article => article) }
  scope :not_this, ->(items) { where("items.id not in (?)",items.map { |itm| itm.id }) }
  scope :filter, ->(search) { joins(:position_code).joins(:article).joins(:article => :manufacturer).where("items.serial LIKE '%#{search}%' OR items.barcode LIKE '%#{search}%' OR articles.barcode LIKE '%#{search}%' OR articles.description LIKE '%#{search}%' OR companies.name LIKE '%#{search}%' OR articles.name LIKE '%#{search}%' OR articles.manufacturerCode LIKE '%#{search}%' OR (#{PositionCode.getQueryFromCode(search)})")}
  scope :lastCreatedOrder, -> { reorder(created_at: :desc) }
  scope :firstCreatedOrder, -> { reorder(created_at: :asc) }
  scope :for_free, -> { where('price <= 0') }
  scope :opened, -> { joins(:article).where( 'items.remaining_quantity < articles.containedAmount and items.remaining_quantity > 0' )}
  scope :unpositioned, -> { where(:position_code => PositionCode.findByCode('P0 #0 0-@')) }
  scope :newestItem, ->(article) { joins(:article).where(article_id: article.id).order(created_at: :desc).limit(1) }
  scope :oldestItem, ->(article) { joins(:article).where(article_id: article.id).order(created_at: :asc).limit(1) }

  enum state: [:nuovo,:usato,:rigenerato,:ricoperto,:riscolpito,:preparato,:danneggiato,:smaltimento]

  @amount = 1
  @actualItems = Array.new

  def to_s
    "Pezzo nr. #{self.id}, #{self.article.complete_name}#{(self.serial.nil? or self.serial == '') ? '' : ', seriale: '+self.serial},  creato il: #{self.created_at}, modificato il: #{self.updated_at}"
  end

  def self.next_available_items(search,excluded = Array.new, from = 0)
    if (from == 0)
      if excluded.nil? or excluded.empty?
        # return Item.available_items.order(:remaining_quantity => :asc, :created_at => :asc).firstGroupByArticle(search,excluded)
        return Item.group_by_article(Item.filter(search).available_items)
      else
        if excluded[0].class == OutputOrderItem
          exc = excluded.map { |itm| itm.item }.reject { |i| i.remaining_quantity > 0 }
        else
          exc = excluded.reject { |i| i.remaining_quantity > 0 }
        end
        # return Item.available_items.not_this(exc).order(:remaining_quantity => :asc, :created_at => :asc).firstGroupByArticle(search,exc)
        if exc.empty?
          return Item.group_by_article(Item.filter(search).available_items)
        else
          return Item.group_by_article(Item.filter(search).available_items.not_this(exc))
        end
      end
    else
      # return Item.firstGroupByArticle(search,excluded,Item.assigned_to(Office.find(from)))
      return Item.group_by_article(Item.filter(search).not_this(excluded.reject { |i| i.item.remaining_quantity > 0 }).order(:remaining_quantity => :asc, :created_at => :asc).assigned_to(Office.find(from)))
    end
  end

  def showLabel
    self.article.complete_name+(self.serial.to_s == '' ? '' : ', Seriale/matricola: '+self.serial)+', posizione: '+self.position_code.code
  end

  def price
   "%.2f" % self[:price].to_f
  end
  # def self.available_items
  #   Item.all.map { |i| i.available? }
  # end
  def real_position
    dst = self.output_orders.where(:destination_type => 'Office').order(:created_at => :desc).first
    byebug
    if dst.nil?
      0
    else
      # if self.remaining_quantity > 0
        dst.destination
      # else
      #   nil
      # end
    end
  end

  def find_next_usable(gonerList,from = 0)

    return self if self.remaining_quantity > 0

    gonerList << self

    gonerList.reverse.each do |i|
      return i if i.article_id == self.article_id and i.remaining_quantity > 0
    end
    if from == 0
      items = Item.article(self.article).not_this(gonerList.select { |i| i.remaining_quantity == 0 }).available_items
    else
      items = Office.find(from).items(self.article,gonerList.select { |i| i.remaining_quantity == 0 })
    end

    # items.to_a.each_with_index do |i,index|
    #   if i == self
    #     return items[index+1] unless items[index+1].nil?
    #   end
    # end

    i = items.first
    i
    # if item.nil?
    #   item = Items.article(self.article).unassigned.order(:created_at => :asc).first
    # end
  end

  def actualPrice
    (self.price.to_f * ((100 - self.discount.to_f) / 100)).round 2
  end

  def self.total_value
    total = 0.0
    Item.unassigned.each do |i|
      total += i.actualPrice
    end
    total
  end

  def self.total_value_no_tyres
    total = 0.0
    Item.unassigned.notyres.each do |i|
      total += i.actualPrice
    end
    total
  end

  def self.total_value_tyres
    total = 0.0
    Item.unassigned.tyres.each do |i|
      total += i.actualPrice
    end
    total
  end

  def complete_price
    price = self.actualPrice.to_s+' €'
    if (self.discount.to_f > 0)
       price += " \n("+self.price.to_s+' -'+self.discount.to_s+'%'+')'
    end
    price.tr('.',',')
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

  def self.group_by_article(list)
    art = Hash.new
    list.reverse.each do |it|
      art[it.article.id.to_s+it.state+it.serial.to_s] = it
    end
    art
  end

  def self.firstGroupByArticle(search_params,gonerList,validList = Array.new)
    art = Hash.new
    # gonerList.map! { |itm| Item.find(itm.id) }
    if validList.empty?
      if gonerList.nil? or gonerList.empty?
        list = Item.available_items.filter(search_params).order(:remaining_quantity => :asc, :created_at => :asc)
      else
        list = Item.not_this(gonerList).available_items.filter(search_params).order(:remaining_quantity => :asc, :created_at => :asc)
      end
    else
      validList.map! { |itm| Item.find(itm) }
      validList -= gonerList
      list = validList
    end
    list.each do |it|
      flag = true
      gonerList.each do |gl|
        if it.id == gl.id
          flag = false
          break
        end
      end
      if flag
        art[it.article.id.to_s+it.state+it.serial.to_s] = it
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
    # if self.item_relations.size > 0
    if self.output_orders.size > 0
      # relation = self.last_order
      return self.output_orders.map { |oo| oo.destination.complete_name }.join(', ')

      # return relation.destination.complete_name
      # unless relation.office.nil?
      #   return relation.office.name+@od
      # end
      # unless relation.vehicle.nil?
      #   return relation.vehicle.plate+@od
      # end
      # unless relation.person.nil?
      #   return relation.person.complete_name+@od
      # end
      # unless relation.worksheet.nil?
      #   return relation.worksheet.complete_name+@od
      # end
      # return self.position_code.code+@od
    else
      # return nil
      return self.position_code.code+@od
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
      :print_density => 9
    )
    # box = Zebra::Epl::Box.new :position => [0, 0], :end_position => [385, 180], :line_thickness => 2
    # label << box
    name = self.article.complete_name.tr('"',"''")
    text  = Zebra::Epl::Text.new :data => self.expiringDate?? 'Sc. '+self.expiringDate.strftime('%d/%m/%Y') : '', :position => [10, 0], :font => Zebra::Epl::Font::SIZE_3
    label << text
    # text  = Zebra::Epl::Text.new :data => self.position_code.code, :position => [220, 10], :font => Zebra::Epl::Font::SIZE_2
    # label << text
    if name.size > 32
      text  = Zebra::Epl::Text.new :data => name[0..31], :position => [10, 30], :font => Zebra::Epl::Font::SIZE_2
      label << text
      text  = Zebra::Epl::Text.new :data => name[32..-1], :position => [10, 50], :font => Zebra::Epl::Font::SIZE_2
      label << text
    else
      text  = Zebra::Epl::Text.new :data => name, :position => [10, 30], :font => Zebra::Epl::Font::SIZE_2
      label << text
    end
    # text  = Zebra::Epl::Text.new :data => self.article.complete_name, :position => [10, 40], :font => Zebra::Epl::Font::SIZE_2
    # label << text
    text  = Zebra::Epl::Text.new :data => (self.serial.nil? || self.serial == '') ? '' : 'Mat. '+self.serial, :position => [10, 70], :font => Zebra::Epl::Font::SIZE_4
    label << text
    barcode = Zebra::Epl::Barcode.new(
      :data                      => self.actualBarcode,
      :position                  => [10, 110],
      :height                    => 40,
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
