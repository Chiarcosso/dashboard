class PositionCodes < ActiveRecord::Migration[5.0]
  def change
    change_table :items do |t|
      t.references :position_code, foreign_key: true
    end
    remove_column :articles, :position_code, :string
    add_reference :articles, :position_code, foreign_key: true
  end
end
