class MdcUserReportNumber < ActiveRecord::Migration[5.0]
  def change
    add_column :mdc_users, :open_documents, :integer, null: false, default: 0, index: true
  end
end
