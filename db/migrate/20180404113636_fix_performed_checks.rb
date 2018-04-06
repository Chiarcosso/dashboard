class FixPerformedChecks < ActiveRecord::Migration[5.0]
  def change
    add_column :vehicle_performed_checks, :mandatory, :boolean, null: false, default: 0
  end
end
