class DefaultExternalVehicleTypology < ActiveRecord::Migration[5.0]
  def change
    remove_foreign_key :external_vehicles, :vehicle_typologies if foreign_key_exists? :external_vehicles, :vehicle_typologies
    remove_column :external_vehicles, :vehicle_typology_id if column_exists? :external_vehicles, :vehicle_typology_id
    add_reference :external_vehicles, :vehicle_typology, null: false, default: 1, index: true, foreign_key: true
  end
end
