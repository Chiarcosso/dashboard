class PositionCodes < ActiveRecord::Migration[5.0]
  def change
    change_table :items do |t|
      t.references :position_code, foreign_key: true unless column_exists? :items, :position_code_id
    end
    remove_column :articles, :position_code, :string if column_exists? :articles, :position_code
    add_reference :articles, :position_code, foreign_key: true
  end
end
