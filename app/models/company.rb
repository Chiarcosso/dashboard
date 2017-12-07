class Company < ApplicationRecord
  resourcify

  belongs_to :company_group
  belongs_to :parent_company, foreign_key: :parent_company_id, class_name: :company
  belongs_to :main_phone_number
  belongs_to :main_mail_address
  belongs_to :main_pec_address
  belongs_to :main_address, foreign_key: :main_company_address_id, class_name: :CompanyAddress

  has_many :owned_vehicles, foreign_key: :property_id, class_name: :vehicle
  has_many :produced_vehicles, foreign_key: :manufacturer_id, class_name: :vehicle
  has_many :produced_articles, foreign_key: :manufacturer_id, class_name: :article
  has_many :items, through: :produced_articles

  has_many :company_addresses
  has_many :company_mail_addresses
  has_many :company_pec_addresses
  has_many :company_phone_numbers

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

  def show_categories
    cats = Array.new
    cats << 'officina' if self.workshop
    cats << 'trasportatore' if self.transporter
    cats << 'cliente' if self.client
    cats << 'fornitore' if self.supplier
    cats << 'produttore di veicoli' if self.vehicle_manufacturer
    cats << 'produttore di materiali' if self.item_manufacturer
    cats << 'istituzione' if self.institution
    cats << 'istituto di formazione' if self.formation_institution
    cats.join(', ').capitalize
  end

  def main_phone_number
    pn = self.main_phone_number
    pn.international_prefix+' '+pn.prefx+' '+pn.number
  end

  def main_mail_address
    self.main_mail_address.address
  end

  def pec_mail_address
    self.pec_mail_address.address
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
