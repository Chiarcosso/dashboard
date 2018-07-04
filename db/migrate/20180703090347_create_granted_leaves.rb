class CreateGrantedLeaves < ActiveRecord::Migration[5.0]
  def change
    create_table :granted_leaves do |t|
      t.references :leave_code, foreign_key: true, null: false, index: true
      t.references :person, foreign_key: true, null: false, index: true
      t.datetime :from, null: false
      t.datetime :to, null: false

      t.timestamps
    end
    add_index :granted_leaves, [:leave_code_id,:person_id,:from,:to], unique: true, name: :granted_leaves_uniqs
  end
end
