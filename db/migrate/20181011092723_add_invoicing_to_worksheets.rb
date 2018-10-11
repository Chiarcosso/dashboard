class AddInvoicingToWorksheets < ActiveRecord::Migration[5.0]
  def change
    add_column :worksheets, :invoicing, :boolean, index: true unless column_exists? :worksheets, :invoicing
    add_reference :worksheets, :customer, foreign_key: {to_table: :companies}, index: true
  end
end
