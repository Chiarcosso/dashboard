class AddStationToCheckSessions < ActiveRecord::Migration[5.0]
  def change
    add_column :vehicle_check_sessions, :station, :string, null: false, default: 'carwash', index: true
  end
end
