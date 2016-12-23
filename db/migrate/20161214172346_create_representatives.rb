class CreateRepresentatives < ActiveRecord::Migration[5.0]
  def change
    create_table :representatives do |t|
      t.references :office
      t.references :user
      t.integer :level

      t.timestamps
    end
  end
end
