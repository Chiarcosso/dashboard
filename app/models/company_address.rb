class CompanyAddress < ApplicationRecord
  resourcify


  belongs_to :company
  belongs_to :geo_city
  belongs_to :geo_locality
  has_one :geo_province, through: :geo_city
  has_one :geo_state, through: :geo_province
  has_many :workshop_brands, foreign_key: :workshop_id
  has_many :brands, through: :workshop_brands

  def address
    a = self.street+' '+self.number
    a += '/'+self.internal unless self.internal.nil? or self.internal == ''
    a += ', '+self.geo_locality.name unless self.geo_locality.nil?
    a += ', '+self.zip+' '+self.geo_city.name+' ('+self.geo_province.code+')'
    a
  end

  def is_main_address?
    if self.company.main_address == self
      true
    else
      false
    end
  end

  def show_categories
    cats = Array.new
    cats << 'officina' if self.workshop
    cats << 'punto di carico' if self.loading_facility
    cats << 'punto di scarico' if self.unloading_facility
    cats.join(', ').capitalize
  end
end
