class AddMdcReportImagesPath < ActiveRecord::Migration[5.0]
  def change
    add_column :mdc_report_images, :path, :string
  end
end
