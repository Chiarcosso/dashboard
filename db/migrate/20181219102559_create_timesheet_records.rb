class CreateTimesheetRecords < ActiveRecord::Migration[5.0]
  def change
    create_table :timesheet_records do |t|
      t.references :person, foreign_key: true, null: false, index: true
      t.references :workshop_operation, foreign_key: true
      t.string :description, null: false
      t.datetime :start
      t.datetime :stop
      t.datetime :hr_approval
      t.datetime :chief_approval
      t.integer  :minutes

      t.timestamps
    end
  end
end
