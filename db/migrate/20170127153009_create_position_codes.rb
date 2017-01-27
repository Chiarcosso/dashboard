class CreatePositionCodes < ActiveRecord::Migration[5.0]
  def change
    create_table :position_codes do |t|
      t.integer :floor, limit: 1, null: false, default: 0
      t.integer :row, limit: 1, null: false, default: 0
      t.integer :level, limit: 1, null: false, default: 0
      t.integer :sector, limit: 1, null: false, default: 0
      t.integer :section, limit: 1, null: false, default: 0
      t.string :description

      t.timestamps
    end
  end
end
