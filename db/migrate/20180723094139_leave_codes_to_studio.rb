class LeaveCodesToStudio < ActiveRecord::Migration[5.0]
  def change
    add_column :leave_codes, :studio_relevant, :boolean, null: false, default: true
    LeaveCode.create(code: 'Ritardo avvisato', description: 'Il dipendente ha avvisato che arriva in ritardo', studio_relevant: false)
    LeaveCode.find_by(code: 'ORIT').update(afterhours: -1)
  end
end
