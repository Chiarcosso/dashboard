class RegistrationModelToVehicles < ActiveRecord::Migration[5.0]
  def change
    add_column :vehicles, :registration_model, :string, null: true, index: true
  end
end
