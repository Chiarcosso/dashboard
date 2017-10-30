class Company < ApplicationRecord
  resourcify

  scope :filter, ->(search) { where('name like ?',"%#{search}%").order(:name) }
  # scope :find_by_name,->(name) { where("lower(name) = ?", name) }

  def self.manufacturerChoice
    find_by_sql('select companies.*, vehicle_models.manufacturer_id as id, count(vehicle_models.manufacturer_id) as cnt from vehicle_models inner join companies on companies.id = vehicle_models.manufacturer_id group by manufacturer_id having manufacturer_id is not null order by cnt desc').first
  end

  def self.propertyChoice
    find_by_sql('select companies.*, vehicles.property_id as id, count(vehicles.property_id) as cnt from vehicles inner join companies on companies.id = vehicles.property_id group by property_id having property_id is not null order by cnt desc').first
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

  def to_s
    self.complete_name
  end

end
