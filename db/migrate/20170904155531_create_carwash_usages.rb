class CreateCarwashUsages < ActiveRecord::Migration[5.0]
  def change
    create_table :carwash_usages do |t|
      t.string :session_id, null: false, unique: true
      t.references :person, foreign_key: true, null: false
      t.references :vehicle_1, foreign_key: {to_table: :vehicles}
      t.references :vehicle_2, foreign_key: {to_table: :vehicles}
      t.string :row, null: false
      t.datetime :starting_time, null: false
      t.datetime :ending_time

      t.timestamps
    end
  end
end
