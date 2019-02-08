class LeaveCodesToStudio < ActiveRecord::Migration[5.0]
  def change
    add_column :leave_codes, :studio_relevant, :boolean, null: false, default: true unless column_exists? :leave_codes, :studio_relevant
    if LeaveCode.find_by(code: 'Ritardo avvisato').nil?
      LeaveCode.create(code: 'Ritardo avvisato', description: 'Il dipendente ha avvisato che arriva in ritardo', studio_relevant: false)
    end
    if LeaveCode.find_by(code: 'ORIT').nil?
      LeaveCode.create(code: 'ORIT')
    end
    LeaveCode.find_by(code: 'ORIT').update(afterhours: -1)
  end
end
