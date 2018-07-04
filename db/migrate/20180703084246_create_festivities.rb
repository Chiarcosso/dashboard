class CreateFestivities < ActiveRecord::Migration[5.0]
  def change
    create_table :festivities do |t|
      t.integer :day, null: false
      t.integer :month, null: false, index: true
      t.integer :year, null: true, index: true
      t.string :name, null:false

      t.timestamps
    end
    add_index :festivities, [:day,:month,:year], unique: true
  end
end
