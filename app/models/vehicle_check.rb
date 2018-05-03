class VehicleCheck < ApplicationRecord
  resourcify
  belongs_to :vehicle
  belongs_to :vehicle_type
  belongs_to :vehicle_typology

  def style_by_importance
    ''
  end

  def select_options
    opts = self.options
    if opts.nil?
      ['Nessuna opzione impostata']
    else
      opts.split('//')
    end
  end
end
