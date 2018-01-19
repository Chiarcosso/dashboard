class CreateVehicleModelTypes < ActiveRecord::Migration[5.0]
  def change
    # `fk_rails_e64af80885
    remove_foreign_key :vehicle_models, :vehicle_types if foreign_key_exists? :vehicle_models, :vehicle_types
    # `index_vehicle_models_on_vehicle_type_id
    remove_index :vehicle_models, :vehicle_type_id if index_exists? :vehicle_models, :vehicle_type_id
    remove_reference :vehicle_models, :vehicle_type
    drop_table :vehicle_model_types
    create_table :vehicle_model_types do |t|
      t.references :vehicle_model, foreign_key: true, null: false, index: true
      t.references :vehicle_type, foreign_key: true, null: false, index: true

      t.timestamps
    end

  end
end
