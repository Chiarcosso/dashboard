class FixCarwashChecks < ActiveRecord::Migration[5.0]
  def change
    add_column :vehicle_performed_checks, :time, :datetime, null: true
    add_index :vehicle_performed_checks, [:vehicle_check_session_id,:vehicle_check_id], unique: true, name: 'vehicle_check_session_check'
  end
end
