class AddOdlSgnRef < ActiveRecord::Migration[5.0]
  def change
    add_column :vehicle_check_sessions, :myofficina_reference, :integer unless column_exists? :vehicle_check_sessions, :myofficina_reference
    add_reference :vehicle_check_sessions, :worksheets, foreign_key: true unless column_exists? :vehicle_check_sessions, :worksheet_id
    add_column :vehicle_performed_checks, :myofficina_reference, :integer
  end
end
