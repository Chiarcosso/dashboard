class FixVehcileChecks < ActiveRecord::Migration[5.0]
  def change
    change_column :vehicle_check_sessions, :worksheet_id, :integer, null: true
    add_reference :vehicle_check_sessions, :vehicle, null: true, foreign_key: true, index: true
    add_reference :vehicle_check_sessions, :external_vehicle, null: true, foreign_key: true, index: true
    execute "ALTER TABLE vehicle_check_sessions ADD CONSTRAINT check_session_vehicle_not_null CHECK (vehicle_id is not null or external_vehicle_id is not null)"
  end
end
