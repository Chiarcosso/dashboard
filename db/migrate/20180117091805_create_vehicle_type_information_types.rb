class CreateVehicleTypeInformationTypes < ActiveRecord::Migration[5.0]
  def change
    unless table_exists? :vehicle_type_information_types
      create_table :vehicle_type_information_types do |t|
        t.references :vehicle_type, foreign_key: true, null: false, index: { name: 'vehicle_type_vehicle_type_index' }
        t.references :vehicle_information_type, foreign_key: true, null: false, index: {name: 'vehicle_type_information_type_index'}

        t.timestamps
      end
    end
    # add_index :vehicle_type_information_types, :vehicle_type, name: 'vehicle_type_vehicle_type_index' unless index_exists? :vehicle_type_information_types, name: 'vehicle_type_vehicle_type_index'
    # add_index :vehicle_type_information_types, :information_type, name: 'vehicle_type_information_type_index' unless index_exists? :vehicle_type_information_types, name: 'vehicle_type_information_type_index'
  end
end
