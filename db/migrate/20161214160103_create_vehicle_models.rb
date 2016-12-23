class CreateVehicleModels < ActiveRecord::Migration[5.0]
  def change
    create_table :vehicle_models do |t|
      t.string :name
      t.integer :type

      t.timestamps
    end
    add_reference(:vehicle_models, :manufacturer, foreign_key: {to_table: :companies})
  end
end
