class AddWorksheetItemRelation < ActiveRecord::Migration[5.0]
  def change
    add_reference(:item_relations, :worksheet, foreign_key: true, null: true)
  end
end
