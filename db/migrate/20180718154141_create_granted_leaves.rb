class CreateGrantedLeaves < ActiveRecord::Migration[5.0]
  def change
    drop_table :granted_leafes if table_exists? :granted_leafes
    unless table_exists? :granted_leaves
      create_table :granted_leaves do |t|
        t.references :leave_code, foreign_key: true, null: false, index: true
        t.references :person, foreign_key: true, null: false, index: true
        t.date :date, index: true
        t.datetime :from, null: false
        t.datetime :to, null: false

        t.timestamps
      end
    end
  end
end
