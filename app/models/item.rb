class Item < ApplicationRecord
  resourcify
  include CharsetUtility
  # include BarcodeUtility
  #
  # require 'barby/outputter/cairo_outputter'
  # # require 'barby/outputter/png_outputter'
  # require 'barby/barcode/code_39'


  belongs_to :article
  belongs_to :transportDocument
  has_many :item_relations

  scope :available_items, -> { joins(:item_relations).where('item_relations.office_id' => nil).where('item_relations.vehicle_id' => nil)}
  scope :article, ->(article) { where(:article => article) }
  scope :filter, ->(search) { joins(:article).where("name LIKE '%#{search}%'").where("articles.name LIKE '%#{search}%'")}
  enum state: [:nuovo,:usato,:rigenerato,:riscolpito,:danneggiato,:smaltimento]

  @amount = 1

  def amount
    @amount
  end

  def setAmount q
    @amount = q
  end

  def position
    relation = self.item_relations.sortBy(:since).last
    unless relation.office.nil?
      return relation.office
    end
    unless relation.vehicle.nil?
      return relation.vehicle
    end
    return nil
  end

  def available?
    self.position.nil?? true : false
  end

  def generateBarcode
    'itm'+ self.id.to_s.rjust(9,"0")
  end

  def printLabel
    label = Zebra::Epl::Label.new(
      :width         => 385,
      :length        => 180,
      :print_speed   => 3,
      :print_density => 6
    )
    # box = Zebra::Epl::Box.new :position => [0, 0], :end_position => [385, 180], :line_thickness => 2
    # label << box
    text  = Zebra::Epl::Text.new :data => self.expiringDate?? 'Sc. '+self.expiringDate.strftime('%d/%m/%Y') : '', :position => [10, 10], :font => Zebra::Epl::Font::SIZE_3
    label << text
    text  = Zebra::Epl::Text.new :data => self.article.position_code, :position => [220, 10], :font => Zebra::Epl::Font::SIZE_2
    label << text
    text  = Zebra::Epl::Text.new :data => self.article.complete_name, :position => [10, 40], :font => Zebra::Epl::Font::SIZE_2
    label << text
    text  = Zebra::Epl::Text.new :data => self.serial.nil?? '' : 'Mat. '+self.serial, :position => [10, 70], :font => Zebra::Epl::Font::SIZE_4
    label << text
    barcode = Zebra::Epl::Barcode.new(
      :data                      => self.barcode,
      :position                  => [30, 120],
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
