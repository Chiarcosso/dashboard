class Article < ApplicationRecord
  resourcify
  include BarcodeUtility
  require 'barby/outputter/cairo_outputter'
  # require 'barby/outputter/png_outputter'
  require 'barby/barcode/ean_13'
  require 'barby/barcode/ean_8'

  has_and_belongs_to_many :categories, class_name: "ArticleCategory",
                                     join_table: "article_categorizations",
                                     foreign_key: :category_id,
                                     association_foreign_key: :article_id

  has_many :items
  belongs_to :manufacturer, class_name: "Company"

  scope :no_barcode, -> { where(barcode: '') }
  scope :manufacturer, ->(search) { include(:company).where("manufacturer_id = companies.id").where("companies.name LIKE '%#{search}%'")}

  enum measure_unit: [:pezzi,:kg,:l]

  def self.incompleteItems
    Article.all
  end

  # def availability
  #   Item.available_items.article(self)
  # end

  def availability(*checked)
    unless checked.empty?
      Item.available_items.unassigned.article(self).to_a - checked[0]
    else
      Item.available_items.unassigned.article(self).to_a
    end
  end

  def setBarcodeImage
    unless self.barcode == ''
      if barcode = checkBarcode(self.barcode,'EAN')
        @blob = Barby::CairoOutputter.new(barcode).to_png #Raw PNG data
        File.write("public/images/#{self.barcode}.png", @blob)
      else
        self.barcode = 'Codice non valido'
      end
    end
  end

  def getManufacturer
    self.manufacturer.nil?? nil : self.manufacturer.id.to_s
  end

  def categoriesList
    list = Array.new
    self.categories.each do |cat|
      list << cat.name
    end
    list.join(', ')
  end

  def manufacturer_name
    if self.manufacturer.nil?
      "Generico"
    else
      self.manufacturer.name
    end
  end

  def complete_name
    unless self.manufacturer.nil?
      self.manufacturer.name + " " + self.manufacturerCode
    else
      "Generico" + " " + self.name.to_s
    end
  end

  # def checkBarcode
  #   begin
  #     if self.barcode[0..-2].size == 12
  #       Barby::EAN13.new(self.barcode[0..-2])
  #     elsif self.barcode[0..-2].size == 7
  #       Barby::EAN8.new(self.barcode[0..-2])
  #     else
  #       return false
  #     end
  #   rescue
  #     return false
  #   end
  # end

end
