class CreateMdcReports < ActiveRecord::Migration[5.0]
  def change
    create_table :mdc_reports do |t|
      t.references :mdc_user, null: false, index: true
      t.string :report_type, null: false, index: true
      t.string :description, null: false
      t.references :vehicle, foreign_key: true, index: true
      t.boolean :maintenance, null: false, default: false, index: :true
      t.boolean :hr, null: false, default: false, index: :true
      t.boolean :logistics, null: false, default: false, index: :true
      t.datetime :sent_at, null: false

      t.timestamps
    end unless table_exists? :mdc_reports
  end
end
