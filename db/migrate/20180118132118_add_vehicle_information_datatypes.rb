class AddVehicleInformationDatatypes < ActiveRecord::Migration[5.0]
  def change
    add_column :vehicle_information_types, :data_type, :integer, null: false, default: 0, index: true
  end
end
