class ItemPersonRelation < ActiveRecord::Migration[5.0]
  def change
    add_reference(:item_relations, :person, foreign_key: true)
  end
end
