class AddMyofficinaToMdcReport < ActiveRecord::Migration[5.0]
  def change
    add_column :mdc_reports, :myofficina_reference, :integer
  end
end
