class ForeignKey < ActiveRecord::Migration[5.0]
  def change
    add_foreign_key :worksheets, :vehicles
  end
end
