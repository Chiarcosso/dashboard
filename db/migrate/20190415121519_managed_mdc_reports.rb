class ManagedMdcReports < ActiveRecord::Migration[5.0]
  def change
    add_reference :mdc_reports, :user, foreign_key: true, index: true unless column_exists? :mdc_reports, :user_id
    add_column :mdc_reports, :managed_at, :datetime
  end
end
