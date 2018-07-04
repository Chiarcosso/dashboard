class CreateLeaveCodes < ActiveRecord::Migration[5.0]
  def change
    create_table :leave_codes do |t|
      t.string :code, null: false, index: true, unique: true
      t.boolean :afterhours, null: false, default: false

      t.timestamps
    end
  end
end
