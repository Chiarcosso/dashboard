class PdfPathInWorksheets < ActiveRecord::Migration[5.0]
  def change
    add_column :worksheets, :pdf_path, :string, null: true
  end
end
