class CreateItemRelations < ActiveRecord::Migration[5.0]
  def change
    create_table :item_relations do |t|
      t.references :office, foreign_key: true
      t.references :vehicle, foreign_key: true
      t.date :since
      t.date :to
      t.timestamps
    end
  end
end
