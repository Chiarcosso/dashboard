class AddNotesToVehicles < ActiveRecord::Migration[5.0]
  def change
    change_table(:vehicles) do |t|
      t.text :notes, null: true
      
    end
  end
end
