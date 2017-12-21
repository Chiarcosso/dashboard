class MobileWorkshopItem < ApplicationRecord
  resourcify

  belongs_to :storage_item, class_name: Item
  belongs_to :mobile_workshop, class_name: Office

  scope :workshop, ->(workshop) { where(mobile_workshop: workshop) }
  scope :filter, ->(search) { joins(:position_code).joins(:article).joins(:article => :manufacturer).where("where mobile_workshop_items.id in (select items.id from items where items.serial LIKE '%#{search.tr(' ','%')}%' OR items.barcode LIKE '%#{search.tr(' ','%')}%' OR articles.barcode LIKE '%#{search.tr(' ','%')}%' OR articles.description LIKE '%#{search.tr(' ','%')}%' OR companies.name LIKE '%#{search.tr(' ','%')}%' OR articles.name LIKE '%#{search.tr(' ','%')}%' OR articles.manufacturerCode LIKE '%#{search.tr(' ','%')}%' OR (#{PositionCode.getQueryFromCode(search.tr(' ','%'))}))")}

  def barcode
    self.storage_item.barcode
  end

  def price
    self.storage_item.price
  end

  def discount
    self.storage_item.discount
  end

  def article
    self.storage_item.article
  end

  def expiration_date
    self.storage_item.expiration_date
  end

  def position_code
    self.storage_item.position_code
  end

  def state
    self.storage_item.state
  end

  def notes
    self.storage_item.notes
  end

  def self.group_by_article(list)
    art = Hash.new
    list.reverse.each do |it|
      art[it.article.id.to_s+it.state+it.serial.to_s] = it
    end
    art
  end

end
