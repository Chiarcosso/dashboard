class VehicleModel < ApplicationRecord
  resourcify
  has_many :vehicles
  belongs_to :vehicle_type
  belongs_to :manufacturer, class_name: 'Company'

  enum vehicle_type: ['Motrice', 'Trattore', 'Rimorchio', 'Semirimorchio', 'Minivan', 'Automobile', 'Furgone', 'Ciclomotore']

  def complete_name
    self.manufacturer.name+' '+self.name
  end

end
