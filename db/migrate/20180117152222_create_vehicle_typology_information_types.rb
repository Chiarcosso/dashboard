class CreateVehicleTypologyInformationTypes < ActiveRecord::Migration[5.0]
  def change
    unless table_exists? :vehicle_typology_information_types
      create_table :vehicle_typology_information_types do |t|
        t.references :vehicle_typology, foreign_key: true, null: false, index: { name: 'vehicle_typology_vehicle_typology_index' }
        t.references :vehicle_information_type, foreign_key: true, null: false, index: { name: 'vehicle_typology_vehicle_information_type_index' }

        t.timestamps
      end
    end
  end
end
