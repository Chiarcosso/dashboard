class VehicleInformationsDateNotNull < ActiveRecord::Migration[5.0]
  def change
    change_column :vehicle_informations, :date, :date, null: false, index: true
  end
end
