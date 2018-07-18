class CreatePresenceRecords < ActiveRecord::Migration[5.0]
  def change
    create_table :presence_records do |t|
      t.date :date, null: false, index: true
      t.references :start_ts, foreign_key: {to_table: :presence_timestamps}, null: false
      t.references :end_ts, foreign_key: {to_table: :presence_timestamps}
      t.references :person, foreign_key: true, index: true
      t.integer :actual_duration
      t.integer :calculated_duration
      t.boolean :break, null: false

      t.timestamps
    end
  end
end
