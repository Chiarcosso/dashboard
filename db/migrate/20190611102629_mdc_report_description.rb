class MdcReportDescription < ActiveRecord::Migration[5.0]
  def change
    change_column :mdc_reports, :description, :text, null: false
  end
end
