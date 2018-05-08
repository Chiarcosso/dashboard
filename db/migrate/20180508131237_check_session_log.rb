class CheckSessionLog < ActiveRecord::Migration[5.0]
  def change
    add_column :vehicle_check_sessions, :log, :text, null: true
    add_column :vehicle_checks, :reference_value_path, :string, null: true
  end
end
