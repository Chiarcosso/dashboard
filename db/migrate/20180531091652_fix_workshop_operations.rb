class FixWorkshopOperations < ActiveRecord::Migration[5.0]
  def change
    add_reference :workshop_operations, :worksheet, null: false, index: true, foreign_key: true unless column_exists? :workshop_operations, :worksheet_id
    add_reference :workshop_operations, :user, null: false, index: true, foreign_key: true unless column_exists? :workshop_operations, :user_id
    add_column :workshop_operations, :starting_time, :datetime
    add_column :workshop_operations, :ending_time, :datetime
    add_column :workshop_operations, :real_duration, :integer, null: false, default: 0
    add_column :workshop_operations, :myofficina_reference, :integer, index: true
    add_column :workshop_operations, :notes, :string
    add_column :workshop_operations, :log, :text
  end
end
