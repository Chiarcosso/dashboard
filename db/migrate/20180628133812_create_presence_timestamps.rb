class CreatePresenceTimestamps < ActiveRecord::Migration[5.0]
  def change
    create_table :presence_timestamps do |t|
      t.references :badge, foreign_key: true, null: false, index: true
      t.datetime :time, null: true
      t.integer :sensor, null: false, index: true
      t.boolean :deleted, null: true, default: false
      t.boolean :added, null: true, default: false
      t.string :file, null: false
      t.integer :row, null: false

      t.timestamps
    end
    add_index :presence_timestamps, [:badge_id,:time,:sensor], unique: true
  end
end
