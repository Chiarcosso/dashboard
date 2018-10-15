class ColorToLeaveCodes < ActiveRecord::Migration[5.0]
  def change
    add_column :leave_codes, :color_code, :string
  end
end
