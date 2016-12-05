class Company < ApplicationRecord
  resourcify

  def self.get(id)
    unless id.nil? or id == ''
      Company.find(id)
    else
      nil
    end
  end
    
end
