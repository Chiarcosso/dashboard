class CreatePeople < ActiveRecord::Migration[5.0]
  def change
    create_table :people do |t|
      t.string :name, null: false, default: ""
      t.string :surname, null: false, default: ""
      t.text :notes

      t.timestamps
    end
  end
end
