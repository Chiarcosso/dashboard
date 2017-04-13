class FixCompaniesAndVehicleInformation < ActiveRecord::Migration[5.0]
  def change
    change_column_null :companies, :name, false
    change_column_null :vehicle_informations, :vehicle_id, false
  end
end
