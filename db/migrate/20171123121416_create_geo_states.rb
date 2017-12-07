class CreateGeoStates < ActiveRecord::Migration[5.0]
  def change
    create_table :languages do |t|
      t.string :name

      t.timestamps
    end
    create_table :geo_states do |t|
      t.string :name, null: false, index: true
      t.string :code, null: false, index: true
      t.references :language, foreign_key: true, null: false

      t.timestamps
    end
  end
end
