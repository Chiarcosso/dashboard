class ChengeVehicleCheckSession < ActiveRecord::Migration[5.0]
  def change
    add_column :vehicle_check_sessions, :finished, :datetime, null: true
  end
end
