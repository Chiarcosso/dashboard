class AddHomePage < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :homepage, :string, null: false, default: '/'
  end
end
