class VehicleModel < ApplicationRecord
  resourcify
  has_many :vehicles
  belongs_to :vehicle_type
  belongs_to :manufacturer, class_name: 'Company'

  # enum vehicle_type: ['Motrice', 'Trattore', 'Rimorchio', 'Rimorchio scarrabile', 'Semirimorchio', 'Minivan', 'Automobile', 'Furgone', 'Ciclomotore', 'Muletto']

  scope :order_by_model, -> { includes(:manufacturer).order('companies.name').order('vehicle_models.name') }

  def self.not_available
    VehicleModel.where(:name => 'N/D').first
  end

  def count
    Vehicle.where(model: self).size
  end

  def complete_name
    m = self.manufacturer.nil?? '' : self.manufacturer.name+' '
    m+self.name
  end

  def to_s
    self.complete_name
  end
end
