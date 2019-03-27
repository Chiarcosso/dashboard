class CreateMdcReportImages < ActiveRecord::Migration[5.0]
  def change
    create_table :mdc_report_images do |t|
      t.references :mdc_report, foreign_key: true, null: false, index: true
      t.string :url, null: false

      t.timestamps
    end unless table_exists? :mdc_report_images
  end
end
