class CreateBadgeAssignments < ActiveRecord::Migration[5.0]
  def change
    create_table :badge_assignments do |t|
      t.references :badge, foreign_key: true, null: false, index: true
      t.references :person, foreign_key: true, null: false, index: true
      t.date :from, null: false
      t.date :to

      t.timestamps
    end
  end
end
