class PlatesOnVehicles < ActiveRecord::Migration[5.0]
  def change
    add_column :vehicles, :creation_plate, :string unless column_exists? :vehicles, :creation_plate
    add_column :vehicles, :current_plate, :string unless column_exists? :vehicles, :current_plate
    
  end
end
