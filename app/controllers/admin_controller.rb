class AdminController < ApplicationController
  require 'roo'
  require 'tiny_tds'

  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :query_params, only: [:send_query]
  require "#{Rails.root}/app/models/mdc_webservice"
  include AdminHelper

  def import_vehicles
    client = TinyTds::Client.new username: 'chiarcosso', password: 'chiarcosso2011!', host: '10.0.0.101', port: 1433, database: 'chiarcosso'
    @results = client.execute("select idveicolo, targa, marca, modello from veicoli "\
                "where marca is not null and marca <> '' and modello is not null and modello <> ''")
    render 'admin/get_vehicles'
  end

  def import_vehicles2
    @results = Array.new
    unless params[:file].nil?
      @data = Roo::Spreadsheet.open(params.require(:file).tempfile)
      #  @data.each_with_pagename do |sheet|
      #     sheet[1].each do |row|
      #       @results << row
      #     end
      #  end
      @model = @data.sheets[0]
      frow = true
      trailer = VehicleType.find_by_name('Rimorchio')
      trailer = VehicleType.create(name: 'Rimorchio', carwash_type: 11) if trailer.nil?
      semitrailer = VehicleType.find_by_name('Semirimorchio')
      semitrailer = VehicleType.create(name: 'Semirimorchio', carwash_type: 6) if semitrailer.nil?
      car = VehicleType.find_by_name('Autovettura')
      car = VehicleType.create(name: 'Autovettura', carwash_type: 13) if car.nil?
      minitruck = VehicleType.find_by_name('Autovettura autocarro')
      minitruck = VehicleType.create(name: 'Autovettura autocarro', carwash_type: 13) if minitruck.nil?
      utility = VehicleType.find_by_name('Autocarro')
      utility = VehicleType.create(name: 'Autocarro', carwash_type: 3) if utility.nil?
      van = VehicleType.find_by_name('Furgone')
      van = VehicleType.create(name: 'Furgone', carwash_type: 13) if van.nil?
      truck = VehicleType.find_by_name('Motrice')
      truck = VehicleType.create(name: 'Motrice', carwash_type: 2) if truck.nil?
      semitruck = VehicleType.find_by_name('Trattore stradale')
      semitruck = VehicleType.create(name: 'Trattore stradale', carwash_type: 2) if semitruck.nil?
      types = [semitrailer,semitruck,trailer,truck,car,van]
      cabin = ['Stretta-bassa','Stretta-media','Stretta-alta','Larga-bassa','Larga-media','Larga-alta','Stretta-bassa-corta']


      at = Company.find_by_name('Autotrasporti Chiarcosso s.r.l.')
      te = Company.find_by_name('Trans Est s.r.l.')
      ed = Company.find_by_name('Edilizia Chiarcosso s.r.l.')
      ed = Company.create(name: 'Edilizia Chiarcosso s.r.l.', vat_number: 'IT00153690300') if ed.nil?

      prev_row = @data.row(1)
      @data.each_row_streaming do |row|
        r = Hash.new
        vehicle = nil
        actual_plate = nil
        row.each_with_index do |cell,index|
          unless cell.value.nil? or cell.value == '' or cell.value == false or cell.value == 'NO' or @data.row(1)[index].upcase == cell.value.to_s.upcase
            # begin
              puts @data.row(1)[index].upcase+' --> '+cell.value.inspect+' ==> '+vehicle.inspect
              case @data.row(1)[index].upcase
              when 'TARGA'
                d = cell.value.upcase.tr('. *','')
                vehicle = Vehicle.find_by_plate(d).first

                if vehicle.nil?
                  vehicle = Vehicle.create(model: VehicleModel.not_available, vehicle_type: VehicleType.not_available, vehicle_typology: VehicleTypology.not_available, property: Company.propertyChoice)
                  # next
                end
                vehicle.registration_date = Date.new(row[4].value.to_i,1,1) if vehicle.registration_date.nil?
                it = VehicleInformationType.find_by_name('Targa')
                it = VehicleInformationType.create(name: 'Targa') if it.nil?
                d = VehicleInformation.find_by_information(cell.value.to_s,it,vehicle)
                d = VehicleInformation.create(information: cell.value.to_s, vehicle_information_type: it, vehicle: vehicle, date: vehicle.registration_date) if d.nil?

                actual_plate = d

              when 'CIRCOLA'
                if cell.value === 'SI' or cell.value === true
                  vehicle.dismissed = true
                else
                  vehicle.dismissed = false
                end
              when 'DITTA'
                case cell.value
                when 'A'
                  d = at
                when 'T'
                  d = te
                when 'E'
                  d = ed
                else
                  d = nil
                end
                vehicle.property = d
              when 'ANNO IMMATRICOLAZIONE'
                vehicle.registration_date = Date.new(cell.value.to_i,1,1)
              when 'MARCA'
                d = Company.find_by_name(cell.value.to_s.humanize.gsub(/\b('?[a-z])/) { $1.capitalize })
                d = Company.create(name: cell.value.to_s.humanize.gsub(/\b('?[a-z])/) { $1.capitalize }) if d.nil?
              when 'TIPO'
                case cell.value
                when 'S'
                  d = types[0]
                when 'R'
                  d = types[2]
                else
                  if cell.value.to_i != 0
                    d = types[cell.value.to_i-1]
                  else
                    d = VehicleType.find_by_name(cell.value)
                    d = VehicleType.create(name: cell.value, carwash_type: 0) if d.nil?
                  end
                end
                vehicle.vehicle_type = d
              when 'TIPOLOGIA'
                d = VehicleTypology.find_by_name(cell.value.to_s.capitalize)
                d = VehicleTypology.create(name: cell.value.to_s.capitalize) if d.nil?
                vehicle.vehicle_typology = d
              when 'NOTE'
                d = cell.value
                vehicle.notes = d
              when 'CODICE AUTOLAVAGGIO'
                d = cell.value.to_i
                vehicle.carwash_code = d
              when 'TELO'
                if cell.value.to_s == 'S'
                  r['Attrezzatura'] = Array.new if r['Attrezzatura'].nil?
                  e = VehicleEquipment.find_by_name('Telo')
                  e = VehicleEquipment.create(name: 'Telo') if e.nil?
                  r['Attrezzatura'] << e
                end
              when 'DIMENSIONE CABINA'
                it = VehicleInformationType.find_by_name(@data.row(1)[index].titleize.capitalize)
                it = VehicleInformationType.create(name: @data.row(1)[index].titleize.capitalize) if it.nil?
                d = VehicleInformation.find_by_information(cell.value.to_s,it,vehicle)
                d = VehicleInformation.create(information: cabin[cell.value.to_i], vehicle_information_type: it, vehicle: vehicle, date: vehicle.registration_date) if d.nil?
              when 'KM'
                d = cell.value.to_i
                vehicle.mileage = d
              when 'DATACAMBIOTARGA'
                r['datacambiotarga'] = cell.value
              when 'EXTARGA'
                d = VehicleInformation.find_by_information(cell.value.to_s,VehicleInformationType.plate,vehicle)
                if d.nil?
                  d = VehicleInformation.create(information: cell.value.to_s, vehicle_information_type: VehicleInformationType.plate, vehicle: vehicle, date: vehicle.registration_date) unless r['datacambiotarga'].nil?
                else
                  d.update(date: vehicle.registration_date)
                end

                actual_plate.update(date: r['datacambiotarga'])
              when 'MODELLO'
                d = VehicleModel.find_by_name(cell.value)
                d = VehicleModel.create(name: cell.value, manufacturer: r['Marca'], vehicle_type: r['Tipo'].nil?? types[0] : r['Tipo']) if d.nil?
                vehicle.model = d

              when 'ATTREZZATURA'
                r['Attrezzatura'] = Array.new if r['Attrezzatura'].nil?
                cell.value.split(' + ').each do |equipment|
                  e = VehicleEquipment.find_by_name(equipment.capitalize)
                  e = VehicleEquipment.create(name: equipment.capitalize) if e.nil?
                  r['Attrezzatura'] << e
                end
              else
                if cell.value === true or cell.value === 'SI'
                  r['Attrezzatura'] = Array.new if r['Attrezzatura'].nil?
                  e = VehicleEquipment.find_by_name(@data.row(1)[index].titleize.capitalize)
                  e = VehicleEquipment.create(name: @data.row(1)[index].titleize.capitalize) if e.nil?
                  r['Attrezzatura'] << e
                else
                  it = VehicleInformationType.find_by_name(@data.row(1)[index].titleize.capitalize)
                  it = VehicleInformationType.create(name: @data.row(1)[index].titleize.capitalize) if it.nil?
                  d = VehicleInformation.find_by_information(cell.value.to_s,it,vehicle)
                  d = VehicleInformation.create(information: cell.value.to_s, vehicle_information_type: it, vehicle: vehicle, date: vehicle.registration_date) if d.nil?
                end
                # d = cell.value.to_s
              end

              d.update(date: vehicle.registration_date) if d.class == VehicleInformation and d.date.nil? and !vehicle.registration_date.nil?
            # rescue
            # #   byebug
            #   d = cell.value.to_s+' '+@data.row(1)[index].titleize.capitalize
            #   byebug
            # end
            r[@data.row(1)[index].titleize.capitalize] = d
          end



        end

        unless r['Targa'].nil? or frow
          r['Veicolo'] = vehicle
          @results << r
          vehicle.registration_date = VehicleInformation.oldest(VehicleInformationType.plate, vehicle).date
          vehicle.save
        end
        frow = false


      end
      # case File.extname(params.require(:file).original_filename)
      # when ".csv" then data = Csv.new(file.path, nil, :ignore)
      # when ".xls" then data = Excel.new(file.path, nil, :ignore)
      # when ".xlsx" then data = Excelx.new(file.path, nil, :ignore)
      #   else byebug
      # end
    end
    render 'admin/get_vehicles'
  end

  def manage
    unless params[:comm].nil?
      @comm = params[:comm]
      begin
        @result = eval(params.require(:comm))
      rescue Exception => e
        @result = e.class.to_s+': '+e.message
      end
    end
    render 'admin/manage'
  end

  def get_vacation

    ws = MdcWebservice.new
    @sessionID = ws.session_id.id
    puts @sessionID
    @results = Array.new
    @results = MdcWebservice.look_for(:vacation)
    render 'admin/soap'
  end

  def get_gear

    ws = MdcWebservice.new
    @sessionID = ws.session_id.id
    puts @sessionID
    @results = Array.new
    @results = MdcWebservice.look_for(:gear)
    render 'admin/soap'
  end

  def queries
    @list = Query.where(:model_class => 'Vehicle').first.nil?? '' : Query.where(:model_class => 'Vehicle').first.query
    render 'admin/query'
  end

  def send_query_vehicles
    @result = RestClient.get "http://portale.chiarcosso/queries/vehicles.php"
    @result = JSON.parse @result.body
    @results = Array.new
    @type = :vehicles
    @result.each do |row|
      row['manufacturer'].gsub!(/\w+/, &:capitalize)
      row['property'].gsub!(/\w+/, &:capitalize)
      row['type'].first.upcase!
      row['vat'].upcase!
      platenumber = row['plate'].upcase.tr('. *','')

      plates = VehicleInformation.where(information: row['plate']).order(date: :asc)
      plates.each do |p|
        p.information = platenumber
        p.save
      end



      manufacturer = Company.find_by(name: row['manufacturer'])
      if manufacturer.nil?
        manufacturer = Company.create(name: row['manufacturer'])
      end
      property = Company.find_by(vat_number: row['vat'])
      if property.nil?
        property = Company.create(name: row['property'], vat_number: row['vat'])
      end
      vehicle_type = VehicleType.find_by(name: row['type'])
      if vehicle_type.nil?
        vehicle_type = VehicleType.create(name: row['type'])
      end
      model = VehicleModel.find_by(name: row['model'])
      if model.nil?
        model = VehicleModel.create(name: row['model'], vehicle_type: vehicle_type, manufacturer: manufacturer)
      end
      plate = VehicleInformation.where(information: platenumber).order(date: :asc).last
      unless plate.nil?
        vehicle = Vehicle.find(plate.vehicle.id)
      end
      if vehicle.nil?
        registration = row['registrationDate'].to_i < 1970 ? nil : Date.new(row['registrationDate'].to_i,1,1)
        vehicle = Vehicle.create(dismissed: (row['dismissed'] == '0'), mileage: row['mileage'], registration_date: registration, property: property, model: model)
        plate = VehicleInformation.create(information_type: VehicleInformation.types['Targa'], information: row['plate'], date: Date.current, vehicle: vehicle)
        chassis = VehicleInformation.create(information_type: VehicleInformation.types['N. di telaio'], information: row['chassis'], date: Date.current, vehicle: vehicle)
        @results << vehicle
      end

    end
    render 'admin/query'
  end

  def send_query_carwash
    result = RestClient.get "http://portale.chiarcosso/queries/carwash.php"
    result = JSON.parse result.body
    results = {:people => Array.new, :vehicles => Array.new}
    result['people'].each do |row|
      person = Person.find_by_complete_name_inv(row['name'])
      unless person.nil?
        results[:people] << CarwashDriverCode.createUnique(person)
      else
        results[:people] << "#{row} - Non trovato"
      end
    end
    result['vehicles'].each do |row|
      vehicle = Vehicle.find_by_plate(row['Targa']).first
      unless vehicle.nil?
        results[:vehicles] << results[:vehicles] << CarwashVehicleCode.createUnique(vehicle)
      else
        results[:vehicles] << "#{row} - Non trovato"
      end
    end
    return results
  end

  def send_query_people
    @result = RestClient.get "http://portale.chiarcosso/queries/people.php"
    @result = JSON.parse @result.body
    @results = Array.new
    @type = :people
    @result.each do |row|
      # @results << row
      if row['company'] == 'A'
        company = Company.find_by(name: 'Autotrasporti Chiarcosso s.r.l.')
      end
      if row['company'] == 'T'
        company = Company.find_by(name: 'Trans Est s.r.l.')
      end

      if (row["name"] == row["surname"])
        names = row["name"].split
        row['surname'] = ''
        row['name'] = names[names.size-1]

        (names.size-1).times do |index|
          row['surname'] += names[index]
          unless index == names.size-1
            row["surname"] += ' '
          end
        end
      end
      person = Person.where(:name => row['name'], :surname => row['surname']).first
      role = CompanyRelation.find_by(name: row['role'])
      if role.nil?
        role = CompanyRelation.create(name: row['role'])
      end
      if person.nil?
        person = Person.create(name: row['name'], surname: row['surname'])
      end
      rel = CompanyPerson.where(person: person, company_relation: role, company: company).first
      if rel.nil?
        CompanyPerson.create(person: person, company_relation: role, company: company)
      end
      @results << person
    end

    render 'admin/query'
  end

  private

  def query_params
    params.require(:model_class)
    # case params.require(:model_class)
    # when 'Vehicle'
    #   @query = %{SELECT Targa AS plate, f.RagioneSoc AS property, anno AS registrationDate,
    #           Marca AS manufacturer, Modello AS model, Telaio AS chassis, Km AS mileage,
    #           FROM Veicoli v
    #           INNER JOIN Fornitori f ON f.IDFornitore = v.IDFornitore
    #           INNER JOIN Tipo t ON t.IDTipo = v.IDTipo
    #         }
    # end
  end

  def authorize_admin
    unless current_user.has_role? :admin
      redirect_to 'home/agenda'
    end
  end

end
