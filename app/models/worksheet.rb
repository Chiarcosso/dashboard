class Worksheet < ApplicationRecord
  resourcify

  belongs_to :vehicle
  scope :filter, ->(search) { where("code LIKE ?",'%'+search+'%') }

  def complete_name
    unless self.code.nil?
      self.code+' (Targa: '+self.vehicle.plate+')'
    else
      'Nuova scheda di lavoro'
    end
  end

  def self.findByCode code
    Worksheet.where(code: code).first
  end
end
