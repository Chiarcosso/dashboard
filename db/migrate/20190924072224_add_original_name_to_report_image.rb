class AddOriginalNameToReportImage < ActiveRecord::Migration[5.0]
  def change
    remove_index :mdc_report_images, :original_filename if index_exists? :mdc_report_images, :index_mdc_report_images_on_original_filename
    add_column :mdc_report_images, :original_filename, :string, null: false, default: '' unless column_exists? :mdc_report_images, :original_filename
    MdcReportImage.all.each{ |ri| ri.update(original_filename: "#{ri.id}") if ri.original_filename.nil? || ri.original_filename == ''}
    add_index :mdc_report_images, :original_filename, unique: true
  end
end
