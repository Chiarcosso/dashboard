class AddDismissedToExternalVehicles < ActiveRecord::Migration[5.0]
  def change
    add_column :external_vehicles, :dismissed, :boolean, null: false, default: false
  end
end
