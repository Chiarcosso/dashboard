class FixChecks < ActiveRecord::Migration[5.0]
  def change
    add_column :vehicle_checks, :measure_unit, :string, null: true
    add_column :vehicle_checks, :datatype, :string, null: false, default: 'select'
    add_column :vehicle_checks, :options, :string, null: true #ordered, //-separated select options. Ex. 'Seleziona_A posto_Aggiustato_Non a posto_Non a posto bloccante_Non applicabile'
    add_column :vehicle_checks, :notify_to, :string, null: true
    change_column :vehicle_performed_checks, :value, :string, null: true
    VehicleCheck.all do |vc|
      if vc.max.nil? and vc.val_min.nil?
        vc.update(options: 'Seleziona//Valore nella norma//Valore fuori norma//Rilevamento impossibile')
      else
        vc.update(datatype: 'decimal(2)')
      end
    end
    VehiclePerformedCheck.performed do |vc|
      vals = ['Seleziona','Valore nella norma','Valore fuori norma','Rilevamento impossibile']
      if vc.vehicle_check.val_max.nil? and vc.vehicle_check.val_min.nil? and !vc.value.nil?
        vc.update(value: vals[vc.value.to_i])
      end
    end
  end

end
