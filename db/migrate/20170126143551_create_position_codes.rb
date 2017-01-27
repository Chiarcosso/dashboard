class CreatePositionCodes < ActiveRecord::Migration[5.0]
  def change
    create_table :position_codes do |t|
      t.string :code, uniq: true

      t.timestamps
    end
  end
end
