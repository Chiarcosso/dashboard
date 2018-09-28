class NoSatelliteVehicles < ActiveRecord::Migration[5.0]
  def change
    add_column :vehicles, :last_gps, :datetime, null: true
    add_column :external_vehicles, :last_gps, :datetime, null: true
    add_column :external_vehicles, :mileage, :integer, null: false, default: 0
  end
end
