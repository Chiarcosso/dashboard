class CreateWorksheetOperations < ActiveRecord::Migration[5.0]
  def change
    create_table :worksheet_operations do |t|
      t.references :worksheet, foreign_key: true
      t.references :workshop_operation, foreign_key: true
      t.datetime :starting_time
      t.datetime :ending_time
      t.references :person, foreign_key: true, index: true

      t.timestamps
    end
  end
end
