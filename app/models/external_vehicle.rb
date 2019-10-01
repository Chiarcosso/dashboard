class ExternalVehicle < ApplicationRecord
  resourcify

  belongs_to :owner, class_name: 'Company'
  belongs_to :vehicle_type
  belongs_to :vehicle_typology

  has_many :worksheets, as: :vehicle
  has_many :mssql_references, as: :local_object, :dependent => :destroy

  scope :filter, ->(search) { where("plate like '%#{search.tr(' ','%').tr('*','%')}%' or vehicle_type_id in (select id from vehicle_types where name like '%#{search.tr(' ','%').tr('*','%')}%') or vehicle_typology_id in (select id from vehicle_typologies where name like '%#{search.tr(' ','%').tr('*','%')}%')"\
                " or owner_id in (select id from companies where name like '%#{search.tr(' ','%').tr('*','%')}%')").distinct }

  def complete_name
    "#{self.plate} - #{self.type.name} #{self.typology.nil? ? 'N/D' : self.typology.name} (#{self.owner.nil? ? 'N/D' : self.owner.name})"
  end

  def property
    self.owner
  end

  def registration_model
    'N/A'
  end

  def model
    'N/A'
  end

  def owners_history
    []
  end

  def last_driver

    msr = self.mssql_references
    case msr.first.remote_object_table
    when 'Veicoli' then
      f = 'idtarga'
    when 'Rimorchi1' then
      f = 'idrimorchi'
    else
      f = nil
    end
    unless f.nil?
      where = msr.map{ |r| "#{f} = #{r.remote_object_id} " }.join(" or ")
      where = "(#{where}) and"
    end
    query = "select top 1 IdAutista as id "\
                "from giornale "\
                "where #{where} idAutista is not null "\
                "and data <= '#{Date.today.strftime('%Y-%m-%d')}' order by data desc;"
    ref = MssqlReference::get_client.execute(query).first
    Person.find_by_reference(ref['id']) unless ref.nil?

  end

  def type
    self.vehicle_type || VehicleType.find_by(name: 'N/D')
  end

  def typology
    self.vehicle_typology || VehicleTypology.find_by(name: 'N/D')
  end

  def category
    VehicleCategory.find_by(name: 'N/D')
  end

  def last_maintainance
    nil
  end

  def last_washing
    nil
  end

  def last_check_session
    VehicleCheckSession.find_by_sql("select * from vehicle_check_sessions where id in "\
              "(select id from vehicle_check_sessions where external_vehicle_id = #{self.id}) "\
              "order by finished desc limit 1").first
  end

  def mileage
    0
  end

  def mandatory?(vc)
    vc.importance == 9 ? true : false
  end

  def registration_date
    return nil
  end

  def vehicle_category
    return nil
  end

  def carwash_code
    return 0
  end

  def vehicle_checks(station)
    case station
    when 'carwash' then
      station_check = 'and check_carwash != 0'
    when 'workshop' then
      station_check = 'and check_workshop != 0'
    end

    VehicleCheck.where("vehicle_type_id = #{self.vehicle_type_id} or vehicle_typology_id = #{self.vehicle_typology_id} #{station_check}").order({importance: :desc, label: :asc})
  end

  def has_reference?(table,id)
    !MssqlReference.where(local_object:self,remote_object_table:table,remote_object_id:id).empty?
  end

  def get_complete_open_eurowin
    eurowin_worksheets = Array.new
    wvehicles = Array.new
    self.mssql_references.each do |msr|
      wvehicles << "CodiceAutomezzo = #{msr.remote_object_id}"
    end

    query = "select * from autoodl where (#{wvehicles.join(' or ')}) "\
              "and FlagSchedaChiusa != 'True' and FlagSchedaChiusa != 'true' "\
              "and FlagProgrammazioneSospesa != 'True' and FlagProgrammazioneSospesa != 'true' "\
              "and DataEntrataVeicolo is not null and DataUscitaVeicolo is null "\
              "order by DataEntrataVeicolo"
    # byebug
    odl = Worksheet.get_client.query(query)
    odl.each do |o|
      current_odl = {protocol: o['Protocollo'], description: o['Note'], date: o['DataIntervento'], plate: o['Targa'], entering_date: o['DataEntrataVeicolo'], exit_date: o['DataUscitaVeicolo'], notifications: Array.new}
      sgn = Worksheet.get_client.query("select * from autosegnalazioni where SerialODL = #{o['Serial']}" )
      sgn.each do |s|
        current_odl[:notifications] << {protocol: s['Protocollo'], description: s['DescrizioneSegnalazione'], operator: s['UserInsert'], date: s['DataInsert']}
      end
      eurowin_worksheets << current_odl
    end
    return eurowin_worksheets unless eurowin_worksheets.empty?
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
