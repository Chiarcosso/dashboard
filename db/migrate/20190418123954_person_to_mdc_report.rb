class PersonToMdcReport < ActiveRecord::Migration[5.0]
  def change
    change_column :mdc_reports, :mdc_user_id, :integer, null: true
    add_reference :mdc_reports, :person, foreign_key: true, null: true, index: true
  end
end
