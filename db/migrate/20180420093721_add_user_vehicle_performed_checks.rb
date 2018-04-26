class AddUserVehiclePerformedChecks < ActiveRecord::Migration[5.0]
  def change
    add_reference :vehicle_performed_checks, :user, null: true
  end
end
