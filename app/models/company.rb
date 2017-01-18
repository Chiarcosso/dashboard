class Company < ApplicationRecord
  resourcify

  scope :manufacturerChoiceScope, -> { where(id: 1) }

  def self.manufacturerChoice
    Company.manufacturerChoiceScope.first
  end

  def self.get(id)
    unless id.nil? or id == ''
      Company.find(id)
    else
      nil
    end
  end

end
