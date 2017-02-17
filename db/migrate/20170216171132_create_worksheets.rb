class CreateWorksheets < ActiveRecord::Migration[5.0]
  def change
    create_table :worksheets do |t|
      t.string :code, null: false, unique: true
      t.date :closingDate
      t.references :vehicle, null: false

      t.timestamps
    end
  end
end
