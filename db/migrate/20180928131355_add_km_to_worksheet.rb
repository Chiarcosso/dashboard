class AddKmToWorksheet < ActiveRecord::Migration[5.0]
  def change
    add_column :worksheets, :mileage, :integer
  end
end
