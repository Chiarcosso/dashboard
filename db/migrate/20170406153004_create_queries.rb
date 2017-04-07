class CreateQueries < ActiveRecord::Migration[5.0]
  def change
    create_table :queries do |t|
      t.string :model_class, null: false, unique: true
      t.text :query, null: false, unique: true

      t.timestamps
    end
  end
end
