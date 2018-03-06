class ExternalVehicle < ApplicationRecord
  resourcify

  belongs_to :owner, class_name: 'Company'
  belongs_to :vehicle_type
  belongs_to :vehicle_typology

  has_many :worksheets, as: :vehicle
  has_many :mssql_references, as: :local_object, :dependent => :destroy
  
  def has_reference?(table,id)
    !MssqlReference.where(local_object:self,remote_object_table:table,remote_object_id:id).empty?
  end

  def check_properties(comp)
    if comp[:owner] != self.owner
      return false
    elsif comp[:vehicle_type] != self.vehicle_type
        return false
    elsif comp[:vehicle_typology] != self.vehicle_typology
      return false
    elsif comp[:idfornitore] != self.id_fornitore
      return false
    end

  return true
  end

end
