class CreateWorkingSchedules < ActiveRecord::Migration[5.0]
  def change
    create_table :working_schedules do |t|
      t.references :person, foreign_key: true, null: false, index: true
      t.time :agreement_from
      t.time :agreement_to
      t.time :contract_from
      t.time :contract_to
      t.integer :weekday, null: false, index: true
      t.boolean :contractor, null: false, index: true, default: false
      t.integer :break, null: false
      t.integer :months_unpaid_days, null: false, default: 0

      t.timestamps
    end
    add_index :working_schedules, [:person_id,:weekday], unique: true
  end
end
