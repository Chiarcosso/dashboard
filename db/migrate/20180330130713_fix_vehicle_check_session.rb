class FixVehicleCheckSession < ActiveRecord::Migration[5.0]
  def change
    change_column :vehicle_check_sessions, :real_km, :integer, null: true
    change_column :vehicle_check_sessions, :real_duration, :integer, null: true
  end
end
