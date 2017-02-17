class ChangeVehicleType < ActiveRecord::Migration[5.0]
  def change
    rename_column :vehicle_models, :type, :vehicle_type
  end
end
