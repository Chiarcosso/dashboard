class AddKmToPerformedChecks < ActiveRecord::Migration[5.0]
  def change
    add_column :vehicle_performed_checks, :km, :integer
  end
end
