class FixWorksheets < ActiveRecord::Migration[5.0]
  def change
    add_column :worksheets, :notes, :string
    add_column :worksheets, :opening_date, :date
  end
end
