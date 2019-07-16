class VehicleCheckSessionsUserrFk < ActiveRecord::Migration[5.0]
  def change
    remove_foreign_key :vehicle_check_sessions, column: :operator_id
    add_foreign_key :vehicle_check_sessions, :users, column: :operator_id, primary_key: 'id'
  end
end
