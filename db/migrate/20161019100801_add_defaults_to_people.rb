class AddDefaultsToPeople < ActiveRecord::Migration[5.0]
  def change
    change_table :people do |t|
      t.change :name, :string, null: false, default: ""
      t.change :surname, :string, null: false, default: ""
    end
  end
end
