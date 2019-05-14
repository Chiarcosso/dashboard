class AddHqToMdcReports < ActiveRecord::Migration[5.0]
  def change
    add_column :mdc_reports, :hq, :boolean, null: false, default: false, index: true
  end
end
