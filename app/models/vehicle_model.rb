class VehicleModel < ApplicationRecord
  resourcify
  has_many :vehicles
  belongs_to :vehicle_type
  belongs_to :manufacturer, class_name: 'Company'

  enum vehicle_type: ['Motrice', 'Trattore', 'Rimorchio', 'Rimorchio scarrabile', 'Semirimorchio', 'Minivan', 'Automobile', 'Furgone', 'Ciclomotore']

  scope :order_by_model, -> { joins(:manufacturer).order('companies.name').order('vehicle_models.name') }
  def complete_name
    self.manufacturer.name+' '+self.name
  end

end
