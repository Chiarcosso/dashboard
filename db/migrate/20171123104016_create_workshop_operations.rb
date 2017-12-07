class CreateWorkshopOperations < ActiveRecord::Migration[5.0]
  def change
    create_table :workshop_operations do |t|
      t.string :name, null: false, index: true
      t.integer :frequency
      t.integer :frequency_mu, limit: 1

      t.timestamps
    end
  end
end
