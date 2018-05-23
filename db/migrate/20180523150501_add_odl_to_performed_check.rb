class AddOdlToPerformedCheck < ActiveRecord::Migration[5.0]
  def change
    add_column :vehicle_performed_checks, :myofficina_odl_reference, :integer, index: true
  end
end
