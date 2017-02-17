class Worksheet < ApplicationRecord
  resourcify

  def self.findByCode code
    Worksheet.where(code: code).first
  end
end
