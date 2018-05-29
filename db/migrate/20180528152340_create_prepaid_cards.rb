class CreatePrepaidCards < ActiveRecord::Migration[5.0]
  def change
    create_table :prepaid_cards do |t|
      t.string :serial, null: false, unique: true
      t.references :person, foreign_key: true, null: true
      t.integer :pin, null: false
      t.boolean :dismissed, null: false, default:false
      t.date :expiring_date, null: false

      t.timestamps
    end
    add_index :prepaid_cards,:serial, unique: true
  end
end
