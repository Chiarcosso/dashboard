class Article < ApplicationRecord
  resourcify

  scope :incomplete, -> { where(barcode: '') }

  def self.incompleteItems
    Article.all
  end

  def checkBarcode
    begin
      Barby::EAN13.new(self.barcode[0..-2])
    rescue
      return false
    end
  end

end
