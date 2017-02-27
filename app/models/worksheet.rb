class Worksheet < ApplicationRecord
  resourcify

  belongs_to :vehicle

  def complete_name
    self.code+' (Targa: '+self.vehicle.plate+')'
  end

  def self.findByCode code
    Worksheet.where(code: code).first
  end
end
