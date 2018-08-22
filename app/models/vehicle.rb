class Vehicle < ApplicationRecord
  include AdminHelper
  include ErrorHelper
  resourcify


  # def self.carwash_codes
  #   ['N/D', 'Trattore standard', 'Motrice scarrabile', 'Autocarro cassone aperto (tre assi)', 'Autocarro cassone chiuso (tre assi)', 'Autocarro speciale', 'Semirimorchio cassone aperto (con e senza sponde idrauliche)', 'Semirimorchio cassone chiuso permanente (centinato - walking floor)', 'Semirimorchio / rimorchio cisterna', 'Rimorchio cassone aperto', 'Rimorchio cassone chiuso permanente (centinato)', 'Rimorchio trasporto mezzi / scarrabile', 'Rimorchio / semirimorchio speciale', 'Auto / furgone']
  # end
  enum carwash_code: ['N/D', 'Trattore standard', 'Motrice scarrabile', 'Autocarro cassone aperto (tre assi)', 'Autocarro cassone chiuso (tre assi)', 'Autocarro speciale', 'Semirimorchio cassone aperto (con e senza sponde idrauliche)', 'Semirimorchio cassone chiuso permanente (centinato - walking floor)', 'Semirimorchio / rimorchio cisterna', 'Rimorchio cassone aperto', 'Rimorchio cassone chiuso permanente (centinato)', 'Rimorchio trasporto mezzi / scarrabile', 'Rimorchio / semirimorchio speciale', 'Auto / furgone']

  belongs_to :model, class_name: 'VehicleModel'
  belongs_to :vehicle_typology
  belongs_to :vehicle_type
  belongs_to :vehicle_category

  has_one :carwash_vehicle_code, :dependent => :destroy
  has_many :carwash_usages_as_first, :foreign_key => 'vehicle_1_id', :class_name => 'CarwashUsage'
  has_many :carwash_usages_as_second, :foreign_key => 'vehicle_2_id', :class_name => 'CarwashUsage'

  has_many :vehicle_check_sessions
  has_many :vehicle_performed_checks, :through => :vehicle_check_sessions
  has_many :vehicle_checks, :through => :vehicle_performed_check

  has_many :vehicle_vehicle_equipments, :dependent => :destroy
  has_many :vehicle_equipments, through: :vehicle_vehicle_equipments
  has_many :vehicle_informations, :dependent => :destroy
  has_many :worksheets

  has_many :mssql_references, as: :local_object, :dependent => :destroy
  has_many :vehicle_properties, :dependent => :destroy
  # has_many :carwash_usages, through: :carwash_vehicle_code
  # has_one :vehicle_type, through: :model
  belongs_to :property, class_name: 'Company'

  # scope :order_by_plate, -> { joins(:vehicle_informations).order('vehicle_informations.information ASC').where('vehicle_informations.vehicle_information_type_id': VehicleInformationType.plate.id) }

  # scope :find_by_plate, ->(plate) { joins(:vehicle_informations).order('vehicle_informations.information ASC, vehicle_informations.date desc').where('vehicle_informations.vehicle_information_type': VehicleInformationType.plate.id).where('vehicle_informations.information LIKE ?','%'+plate+'%') }
  # scope :find_by_plate, -> (plate) { where("id in (select vehicle_id from vehicle_informations where vehicle_information_type_id = #{VehicleInformationType.plate.id} and information = '#{plate.upcase}')").last }
  scope :order_by_chassis, -> { joins(:vehicle_informations).order('vehicle_informations.information ASC').where('vehicle_informations.vehicle_information_type': VehicleInformationType.chassis.id) }
  scope :find_by_chassis, ->(chassis) { joins(:vehicle_informations).order('vehicle_informations.information ASC, date desc').where('vehicle_informations.vehicle_information_type': VehicleInformationType.chassis.id).where('vehicle_informations.information LIKE ?','%'+chassis+'%') }
  scope :find_by_manufacturer, ->(manufacturer) { joins(:model).joins('vehicle_models.manufacturer').where('companies.name LIKE ?', '%'+manufacturer+'%') }
  scope :filter_by_model, ->(search) { joins(:model).where('vehicle_models.name LIKE ?', '%'+search+'%') }
  scope :filter_by_property, ->(property) { joins(:property).where('companies.name LIKE ?', '%'+property+'%') }
  scope :null_scope, -> { where(id: nil) }
  scope :with_worksheets, -> { where("id in (select vehicle_id from worksheets)") }
  scope :free_to_delete, -> { where("id not in (select vehicle_id from worksheets) and id not in (select destination_id from output_orders where destination_type = 'Vehicle')")}
  scope :not_free_to_delete, -> { where("id in (select vehicle_id from worksheets) or id in (select destination_id from output_orders where destination_type = 'Vehicle')")}
  scope :no_reference, -> { where("id not in (select local_object_id from mssql_references where local_object_type = 'Vehicle')")}
  # scope :filter, ->(search) { joins(:vehicle_informations).joins(:model).joins('left join vehicle_types on vehicle_types.id = vehicles.vehicle_type_id').joins('left join vehicle_typologies on vehicle_typologies.id = vehicles.vehicle_typology_id').joins('inner join companies on vehicle_models.manufacturer_id = companies.id').joins('inner join companies prop on vehicles.property_id = prop.id').where("vehicle_informations.information LIKE '%#{search.tr(' ','%').tr('*','%')}%' or vehicle_models.name LIKE '%#{search.tr(' ','%').tr('*','%')}%' or companies.name LIKE '%#{search.tr(' ','%').tr('*','%')}%' or prop.name LIKE '%#{search.tr(' ','%').tr('*','%')}%' or vehicle_types.name LIKE '%#{search.tr(' ','%').tr('*','%')}%' or vehicle_typologies.name LIKE '%#{search.tr(' ','%').tr('*','%')}%'").distinct }
  scope :filter, ->(search) { joins("left join vehicle_informations on vehicle_informations.vehicle_id = vehicles.id").where("vehicle_type_id in (select id from vehicle_types where name like '%#{search.tr(' ','%').tr('*','%')}%') or vehicle_typology_id in (select id from vehicle_typologies where name like '%#{search.tr(' ','%').tr('*','%')}%')"\
                " or property_id in (select id from companies where name like '%#{search.tr(' ','%').tr('*','%')}%') or model_id in (select id from vehicle_models where name like '%#{search.tr(' ','%').tr('*','%')}%' or manufacturer_id in (select id from companies where name like '%#{search.tr(' ','%').tr('*','%')}%'))"\
                " or vehicle_informations.information like '%#{search.tr(' ','%').tr('*','%')}%' or vehicles.id in (select vehicle_id from vehicle_vehicle_equipments inner join vehicle_equipments on vehicle_vehicle_equipments.vehicle_equipment_id = vehicle_equipments.id where vehicle_equipments.name like '%#{search.tr(' ','%').tr('*','%')}%')").distinct }


  # scope :filter, ->(search) { find_by_plate(search).or(find_by_chassis(search)).or(find_by_model(search)).or(find_by_manufacturer(search)) }

  self.per_page = 30

  def type
    if self.vehicle_type.nil?
      ''
    else
      self.vehicle_type.name
    end
  end

  def last_maintainance
    lm = EurowinController::last_maintainance(self)
    if lm.nil?
      nil
    else
      Worksheet.find_by(code: "EWC*#{lm['Protocollo']}")
    end
  end

  def self.get_satellite_data
    r = Hash.new

    request = HTTPI::Request.new
    request.url = ENV['RAILS_SELECTA_URL']
    request.headers['Content-Type'] = 'text/xml; charset=utf-8'
    request.headers['Expect'] = '100-continue'
    request.headers['Connection'] = 'Keep-Alive'
    request.headers['SOAPAction'] = "http://selecta.ve.it/selsystem/ISelSystemExport/GetTotalsKmList"
    request.body = '<?xml version="1.0" encoding="UTF-8"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body><GetTotalsKmList xmlns="http://selecta.ve.it/selsystem"><request xmlns:i="http://www.w3.org/2001/XMLSchema-instance"><SecurityToken i:type="UserNamePasswordCompanyToken"><CompanyID>'+ENV['RAILS_SELECTA_COMPANY_ID']+'</CompanyID><Password>'+ENV['RAILS_SELECTA_PASS']+'</Password><UserName>'+ENV['RAILS_SELECTA_USERNAME']+'</UserName></SecurityToken><UniqueId>'+ENV['RAILS_SELECTA_UNIQUE_ID']+'</UniqueId></request></GetTotalsKmList></s:Body></s:Envelope>'
    res = HTTPI.post(request)
    res.body.scan(/<TotalKmInfo><CC>.*?<\/CC><DV>.*?<\/DV><KM>(.*?)<\/KM><PL>(.*?)<\/PL><\/TotalKmInfo>/) do |line|
      r[line[1].tr(' -.','')] = line[0]
    end

    request = HTTPI::Request.new
    request.url = "#{ENV['RAILS_CVS_URL']}DataAPI/VehicleList/json?#{ENV['RAILS_CVS_AUTH_PARAMS']}"
    request.headers['Content-Type'] = 'application/json; charset=utf-8'
    res = HTTPI.post(request)

    JSON.parse(res.body)['data']['Vehicles']['Vehicle'].each do |v|
      r[v['VehiclePlateNumber'].tr(' -.','')] = v['Odometer']
    end

    r
  end

  def self.update_km

    Vehicle.get_satellite_data.each do |k|

      begin
        v = Vehicle.find_by_plate(k[0])
        if v.mileage > k[1].to_i
          v.update(mileage: k[1].to_i)
        end
      rescue Exception => e
        @error = e.message+"\n\n"+k.inspect
        puts @error
      end
    end

  end

  def update_km
    data = Vehicle.get_satellite_data
    self.update(mileage: data[self.plate])

  end

  def typology
    if self.vehicle_type.nil? or self.vehicle_typology == VehicleTypology.not_available
      ''
    else
      self.vehicle_typology.name
    end
  end

  def self.find_by_reference(table,id)
    v = MssqlReference.find_by(remote_object_table: table, remote_object_id: id)
	  v.local_object unless v.nil?
    # find and create new vehicle if v.nil?
  end

  def mandatory?(vc)
    vc.importance == 9 ? true : false
  end

  def vehicle_checks(station)
    case station
    when 'carwash' then
      station_check = 'and check_carwash != 0'
    when 'workshop' then
      station_check = 'and check_workshop != 0'
    end
    # VehicleCheck.where("(vehicle_type_id = #{self.vehicle_type_id} and vehicle_typology_id = #{self.vehicle_typology_id}) #{station_check}").order({importance: :desc, label: :asc})
    VehicleCheck.where("((vehicle_type_id = #{self.vehicle_type_id} and vehicle_typology_id = #{self.vehicle_typology_id}) or (vehicle_type_id = #{self.vehicle_type_id} and vehicle_typology_id is null) or (vehicle_type_id is null and vehicle_typology_id = #{self.vehicle_typology_id}) or (vehicle_type_id is null and vehicle_typology_id is null)) #{station_check}").order({importance: :desc, label: :asc})
  end

  def get_complete_open_eurowin
    eurowin_worksheets = Array.new
    wvehicles = Array.new
    self.mssql_references.each do |msr|
      wvehicles << "CodiceAutomezzo = #{msr.remote_object_id}"
    end
    query = "select autoodl.*, (select descrizione from tabdesc where codice = autoodl.codicetipodanno and gruppo = 'AUTOTIPD') as descrizione "\
              "from autoodl "\
              "where (#{wvehicles.join(' or ')}) "\
              "and FlagSchedaChiusa != 'True' and FlagSchedaChiusa != 'true' "\
              "and FlagProgrammazioneSospesa != 'True' and FlagProgrammazioneSospesa != 'true' "\
              "and DataUscitaVeicolo is null "\
              "order by DataEntrataVeicolo"

    ewc = EurowinController.get_ew_client
    odl = ewc.query(query)
    ewc.close
    odl.each do |o|
      current_odl = {protocol: o['Protocollo'], description: "#{o['descrizione'].nil?? '' : o['descrizione']+' - ' }#{o['Note']}", date: o['DataIntervento'], plate: o['Targa'], entering_date: o['DataEntrataVeicolo'], exit_date: o['DataUscitaVeicolo'], notifications: Array.new}
      ewc = EurowinController.get_ew_client
      sgn = ewc.query("select * from autosegnalazioni where SerialODL = #{o['Serial']}" )
      ewc.close
      sgn.each do |s|
        current_odl[:notifications] << {protocol: s['Protocollo'], description: s['DescrizioneSegnalazione'], operator: "#{s['UserInsert']} (#{s['UserPost']})", date: s['DataInsert']}
      end
      eurowin_worksheets << current_odl
    end
    return eurowin_worksheets
  end

  def self.get_or_create_by_reference(table, id)
    begin
      mr = MssqlReference.find_by(remote_object_table: table, remote_object_id: id.to_i)
      v = mr.local_object unless mr.nil?

      if v.nil?
        case table
        when 'Veicoli' then
          query = "select 'Veicoli' as table_name, idveicolo as id, targa as plate, telaio as chassis, "\
                      "Tipo.Tipodiveicolo as type, (case when veicoli.idfornitore = 749 then 'E' else ditta end) as property, marca as manufacturer, "\
                      "clienti.ragioneSociale as owner, veicoli.idfornitore, "\
                      "modello as model, modello2 as registration_model, codice_lavaggio as carwash_code, "\
                      "circola as notdismissed, tipologia.[tipologia semirimorchio] as typology, KmAttuali as mileage, "\
                      "ISNULL(convert(nvarchar, data_immatricolazione,126),convert(nvarchar,ISNULL(anno,1900))+'-01-01') as registration_date, categoria as category, motivo_fuori_parco "\
                      "from veicoli "\
                      "left join clienti on veicoli.IDfornitore = clienti.codtraffico "\
                      "left join Tipo on veicoli.IDTipo = Tipo.IDTipo "\
                      "left join [Tipologia rimorchio/semirimorchio] tipologia on veicoli.Id_Tipologia = tipologia.ID "\
                      "where idveicolo = #{id}"
          ref = MssqlReference::get_client.execute(query).first
          unless ref.nil?
            if ref['property'] == 'A' or ref['property'] == 'T' or  ref['property'] == 'E'
              VehiclesController.helpers.create_vehicle_from_veicoli ref
              v = Vehicle.find_by_reference(ref['table_name'],ref['id'])
            else
              VehiclesController.helpers.create_external_vehicle_from_veicoli ref
              v = Vehicle.find_by_reference(ref['table_name'],ref['id'])
            end
          end
        when 'Rimorchi1' then
          # query = "select 'Rimorchi1' as table_name, idrimorchio as id, targa as plate, telaio as chassis, "\
          #             "(case tipo) as type, ditta as property, marca as manufacturer, "\
          #             "modello as model, modello2 as registration_model, codice_lavaggio as carwash_code, "\
          #             "circola as notdismissed, tipologia.[tipologia semirimorchio] as typology, KmAttuali as mileage, "\
          #             "ISNULL(convert(nvarchar, data_immatricolazione,126),convert(nvarchar,ISNULL(anno,1900))+'-01-01') as registration_date, categoria as category, motivo_fuori_parco "\
          #             "from veicoli "\
          #             "left join Tipo on veicoli.IDTipo = Tipo.IDTipo "\
          #             "left join [Tipologia rimorchio/semirimorchio] tipologia on veicoli.Id_Tipologia = tipologia.ID "\
          #             "where idveicolo = #{id}"
          query = "select 'Rimorchi1' as table_name, idrimorchio as id, targa as plate, telaio as chassis, "\
                      "(case Tipo when 'S' then 'Semirimorchio' when 'R' then 'Rimorchio' end) as type, ditta as property, "\
                      "marca as manufacturer, (case Tipo when 'S' then 'Semirimorchio' when 'R' then 'Rimorchio' end) as model, "\
                      "clienti.ragioneSociale as owner, rimorchi1.idfornitore, "\
                      "(case Tipo when 'S' then 'Semirimorchio' when 'R' then 'Rimorchio' end) as registration_model, "\
                      "codice_lavaggio as carwash_code, circola as notdismissed, "\
                      "tipologia.[tipologia semirimorchio] as typology, Km as mileage, "\
                      "ISNULL(convert(nvarchar, data_immatricolazione,126),convert(nvarchar,ISNULL(anno,1900))+'-01-01') as registration_date, "\
                      "categoria as category, motivo_fuori_parco "\
                      "from rimorchi1 "\
                      "inner join clienti on rimorchi1.IDfornitore = clienti.codtraffico "\
                      "left join [Tipologia rimorchio/semirimorchio] tipologia on rimorchi1.[Tipologia Rimonchio/Semirimorchio] = tipologia.ID "\
                      "where idrimorchio = #{id}"
          ref = MssqlReference::get_client.execute(query).first

          unless ref.nil?
            if ref['property'] == 'A' or ref['property'] == 'T' or  ref['property'] == 'E'
              VehiclesController.helpers.create_vehicle_from_veicoli ref
              v = Vehicle.find_by_reference(ref['table_name'],ref['id'])
            else
              VehiclesController.helpers.create_external_vehicle_from_veicoli ref
              v = Vehicle.find_by_reference(ref['table_name'],ref['id'])
            end
          end
        when 'Altri mezzi' then
          query = "select 'Altri mezzi' as table_name, convert(int,cod) as id, targa as plate, telaio as chassis, "\
                      "tipo.tipodiveicolo as type, ditta as property, numero_posti as posti_a_sedere, "\
                      "marca as manufacturer, modello as model, modello as registration_model, "\
                      "codice_lavaggio as carwash_code, circola as notdismissed, "\
                      "tipologia.[tipologia semirimorchio] as typology, Km as mileage, "\
                      "ISNULL(convert(nvarchar, data_immatricolazione,126),convert(nvarchar,ISNULL(anno,1900))+'-01-01') as registration_date, "\
                      "categoria as category, motivo_fuori_parco "\
                      "from [Altri mezzi] "\
                      "left join Tipo on Tipo.IDTipo = [Altri mezzi].id_tipo "\
                      "left join [Tipologia rimorchio/semirimorchio] tipologia on [Altri mezzi].id_tipologia = tipologia.ID "\
                      "where cod = #{id}"
          ref = MssqlReference::get_client.execute(query).first
          unless ref.nil?
            if ref['property'] == 'A' or ref['property'] == 'T' or  ref['property'] == 'E'
              VehiclesController.helpers.create_vehicle_from_veicoli ref
              v = Vehicle.find_by_reference(ref['table_name'],ref['id'])
            else
              VehiclesController.helpers.create_external_vehicle_from_veicoli ref
              v = Vehicle.find_by_reference(ref['table_name'],ref['id'])
            end
          end
        end
      end
    rescue Exception => e
      # @error = e.message unless
      raise e.message
    end
    v
  end

  def long_label
    begin
      "ID: #{self.id}; proprietà: #{self.property.name}; targa: #{self.plate}; modello: #{self.model.complete_name}; tipo: #{self.vehicle_type.name}; tipologia: #{self.vehicle_typology.name}; "\
      "categoria: #{self.vehicle_category.name}; telaio: #{self.chassis_number}; attrezzatura: #{self.vehicle_equipments.pluck(:name).join(', ')}; info: #{self.vehicle_informations.map { |i| i.complete_information }.join(', ')}"
    rescue Exception => e
      e.message
    end
  end

  def has_property?(property=nil)
    if property.nil?
      !VehicleProperty.where(vehicle:self).empty?
    else
      !VehicleProperty.where(vehicle:self,owner: property).empty?
    end
  end

  def actual_property
    VehicleProperty.where(vehicle: self).order(date_since: :desc).first
  end

  def owners_history
    VehicleProperty.where(vehicle: self).where("id <> #{self.actual_property.id}").order(date_since: :desc)
  end

  def has_reference?(table,id)
    !MssqlReference.where(local_object:self,remote_object_table:table,remote_object_id:id).empty?
  end

  def check_properties(comp)
    if comp['property'] == 'T' and self.property != Company.transest or comp['property'] == 'A' and self.property != Company.chiarcosso
      return false
    # elsif comp['plate'].upcase.tr('. *','') != self.plate
    #   return false
  elsif (comp['mileage'].to_i > self.mileage.to_i)
      return false
    elsif comp['notdismissed'] == self.dismissed
      return false
    elsif comp['manufacturer'].upcase != self.model.manufacturer.name.upcase
      return false
    elsif comp['model'].upcase != self.model.name.upcase
      return false
    elsif !comp['registration_date'].nil? && (DateTime.parse(comp['registration_date']) != self.registration_date)
      return false
    elsif comp['carwash_code'] != self.carwash_code
      return false
    end
    return true
  end

  def self.find_by_plate(plate)
    v = Vehicle.where("id in (select vehicle_id from vehicle_informations where vehicle_information_type_id = #{VehicleInformationType.plate.id} and upper(information) = '#{plate.upcase}')").last
    v = ExternalVehicle.where("upper(plate) = '#{plate.to_s.gsub("'","''").upcase}'").last if v.nil?
    v
  end

  def possible_information_types
    self.vehicle_typology.vehicle_information_types & self.vehicle_type.vehicle_information_types
  end

  def get_vehicle_informations
    @informations = self.vehicle_informations
    info = (self.vehicle_type.vehicle_information_types + self.vehicle_typology.vehicle_information_types).uniq
    missing_informations = Array.new
    info.each { |i| missing_informations << VehicleInformation.new(vehicle_information_type: i, vehicle: self) unless @informations.map { |vi| vi.vehicle_information_type }.include? i}
    # missing_informations.reject! { |i| @informations.map { |vi| vi.vehicle_information_type }.include? i }
    @informations += missing_informations
    @informations -= [self.last_information(VehicleInformationType.plate),self.last_information(VehicleInformationType.chassis)]
    @informations = @informations.sort_by { |i| [i.vehicle_information_type.name,i.date] }.reverse.sort_by { |i| [i.vehicle_information_type.name] }
  end

  def get_equipment
    e = self.vehicle_equipments.sort_by { |e| e.name }
    e + ((self.vehicle_type.vehicle_equipments + self.vehicle_typology.vehicle_equipments).uniq.sort_by{ |e| e.name } - e)
  end

  def last_vehicle_informations
    self.vehicle_informations.select { |i| i == self.last_information(i.vehicle_information_type) }.sort_by{ |i| i.vehicle_information_type.name }
  end

  def last_checks
    tmp = Hash.new
    lc = Array.new
    self.vehicle_performed_checks.performed.each do |vc|
      tmp[vc.vehicle_check.id] = Array.new if tmp[vc.vehicle_check.label].nil?
      tmp[vc.vehicle_check.id] << vc
    end
    tmp.each do |k,a|
      a.sort { |c,d| c.time<=>d.time }
      lc << a.last
    end
    lc.sort { |c,d| -c.performed<=>-d.performed}
  end

  def get_types
    # if self.vehicle_type == VehicleType.not_available or self.vehicle_typology == VehicleTypology.not_available
      VehicleType.all.order(:name)
    # else
    #   self.vehicle_typology.vehicle_types && self.model.vehicle_types
    # end
  end

  def get_carwash_code
    self.vehicle_type.carwash_type
  end

  def get_categories
    self.vehicle_type.vehicle_categories
  end

  def get_typologies
    # if self.vehicle_typology == VehicleTypology.not_available or self.vehicle_model.nil?
    #   VehicleTypology.all
    # else
    VehicleTypology.all.order(:name)
      # (self.vehicle_type.vehicle_typologies & self.vehicle_category.vehicle_typologies).sort_by { |i| i.name }
    # end
  end


  def get_models
    # (self.vehicle_typology.vehicle_models & self.vehicle_typology.vehicle_models).sort_by { |m| m.complete_name}
    VehicleModel.all.manufacturer_model_order
  end

  def last_washing
    cws = self.carwash_usages.reject{ |cw| cw.ending_time.nil? }
    cws.sort_by { |cwu| cwu.ending_time }.reverse.first unless cws.empty?
  end

  def last_check_session
    VehicleCheckSession.find_by_sql("select * from vehicle_check_sessions where id in "\
              "(select id from vehicle_check_sessions where vehicle_id = #{self.id}) "\
              "order by finished desc limit 1").first
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
      where = msr.map{ |r| "#{f} = #{r.remote_object_id} and " }.join(" or ")
    end
    query = "select top 1 IdAutista as id "\
                "from giornale "\
                "where #{where} idAutista is not null "\
                "and data <= '#{Date.today.strftime('%Y-%m-%d')}' order by data desc;"
    ref = MssqlReference::get_client.execute(query).first
    Person.find_by_reference(ref['id']) unless ref.nil?

  end

  def carwash_usages
    self.carwash_usages_as_first + self.carwash_usages_as_second
  end

  def just_washed?
    unless self.last_washing.nil? or self.last_washing.starting_time + 1.days < DateTime.now
      true
    else
      false
    end
  end

  def find_information(type)
    p = self.vehicle_informations.where(:vehicle_information_type => type.id).order(created_at: :desc).limit(1).first
    if p.nil?
      ''
    else
      p.information.upcase
    end
  end

  def plate
    p = self.last_information(VehicleInformationType.plate)
    if p.nil? or p.information.nil?
      ''
    else
      p.information
    end
  end

  def last_information(information_type)
    if information_type.class != VehicleInformationType
      information_type = VehicleInformationType.find_by_name(information_type)
    end
    VehicleInformation.where(vehicle: self).where(vehicle_information_type: information_type).order(:date).last
  end

  def chassis_number

    c = self.last_information(VehicleInformationType.chassis)
    if c.nil?
      ''
    else
      c.information
    end
  end

  def complete_name
    self.plate+' '+self.model.complete_name
  end


end
