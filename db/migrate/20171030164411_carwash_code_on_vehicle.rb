class CarwashCodeOnVehicle < ActiveRecord::Migration[5.0]
  def change
    add_column(:vehicles, :carwash_code, :integer, null: true, default: nil)
  end
end
