class AddWorkshopLabel < ActiveRecord::Migration[5.0]
  def change
    add_column :worksheets, :workshop_label, :string, index: true
  end
end
