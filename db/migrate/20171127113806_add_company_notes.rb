class AddCompanyNotes < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :notes, :string, null: true unless column_exists? :copmanies, :notes
  end
end
