class CreateVehicleModelInformationTypes < ActiveRecord::Migration[5.0]
  def change
    create_table :vehicle_model_information_types do |t|
      t.references :vehicle_model, foreign_key: true, null: false, index: { name: 'vehicle_model_vehicle_model_index' }
      t.references :vehicle_information_type, foreign_key: true, null: false, index: { name: 'vehicle_model_vehicle_information_type_index' }

      t.timestamps
    end
  end
end
