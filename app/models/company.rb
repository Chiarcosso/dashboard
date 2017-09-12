class Company < ApplicationRecord
  resourcify

  scope :manufacturerChoiceScope, -> { where(id: 1) }
  scope :filter, ->(search) { where('name like ?',"%#{search}%").order(:name) }
  # scope :find_by_name,->(name) { where("lower(name) = ?", name) }

  def self.manufacturerChoice
    Company.manufacturerChoiceScope.first
  end

  def self.find_by_name name
    Company.where("lower(name) = ?", name).first
  end

  def self.get(id)
    unless id.nil? or id == ''
      Company.find(id)
    else
      nil
    end
  end

  def list_name
    self.name
  end

  def complete_name
    self.name
  end

end
