class CreateVehicleInformationTypes < ActiveRecord::Migration[5.0]
  def change
    create_table :vehicle_information_types do |t|
      t.string :name, null: false

      t.timestamps
    end
    VehicleInformationType.create(:name => 'Targa')
    VehicleInformationType.create(:name => 'N. di telaio')
  end
end
