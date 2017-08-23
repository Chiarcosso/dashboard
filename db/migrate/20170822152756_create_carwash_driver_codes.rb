class CreateCarwashDriverCodes < ActiveRecord::Migration[5.0]
  def change
    create_table :carwash_driver_codes do |t|
      t.string :code, null: false, unique: true, index: true
      t.references :person, foreign_key: true, null: true

      t.timestamps
    end
  end
end
