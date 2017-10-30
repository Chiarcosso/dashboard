class CreateGears < ActiveRecord::Migration[5.0]
  def change
    create_table :gears do |t|
      t.string :name, null: false, unique: true
      t.string :serial, null: false
      t.integer :assigned_to
      t.string :assigned_to_class

      t.timestamps
    end
  end
end
