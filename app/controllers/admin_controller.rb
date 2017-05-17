class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :query_params, only: [:send_query]

  def soap
    user = 'chiarcosso_ws'
    passwd = 'MfE3isk2Z0'
    endpoint = 'http://chiarcosso.mobiledatacollection.it/mdc_webservice/services/MdcServiceManager'
    # endpoint = 'http://192.168.88.10:80/mdc_webservice/services/MdcServiceManager'

    client = Savon.client(
                  :wsdl => endpoint+"?wsdl",
                  :ssl_verify_mode => :none,
                  :endpoint => endpoint,
                  :raise_errors => false,
                  :open_timeout => 120,
                  :read_timeout => 120
                  )

    # puts "\n"
    # puts '--------'+endpoint+"?wsdl"+'----------------'+"\n"
    # puts "\n"
    # puts client.operations.size.to_s+' operazioni:'+"\n"
    # puts "\n"

    # client.operations.sort.each do |o|
    #   puts o.to_s+"\n"
    # end

    # -- Operations list --
    #
    # begin_transaction
    # begin_transaction_with_isolation_level
    # check_configuration
    # close_session
    # commit_transaction
    # delete_tabgen
    # delete_tabgen_by_selector
    # download_file
    # echo
    # end_transaction
    # insert_or_update_tabgen
    # insert_or_update_tabgen_list
    # insert_tabgen
    # open_session
    # rollback_transaction_changes
    # select_application_gps_record
    # select_application_gps_records
    # select_data_collection_extra_heads
    # select_data_collection_extra_rows
    # select_data_collection_heads
    # select_data_collection_rows
    # select_device_gps_records
    # select_devices_by_alternative_code
    # select_devices_by_code
    # select_devices_by_username
    # select_tabgen
    # select_tabgen_by_selector
    # send_push_notification
    # send_push_notification_ext
    # send_same_push_notification_ext
    # send_same_push_notification_ext_raw
    # update_data_collection_extra_rows_status
    # update_data_collection_rows_status
    # update_device_reference
    # upload_file
    # upload_image

    # puts "\n"
    # puts '--------'+endpoint+'---------------------'+"\n"
    # puts "\n"

    begin
    response = client.call(:open_session, message: {useSharedDatabaseConnection: 0, username: user, password: passwd})

    rescue Savon::SOAPFault => error
      # puts Logger.methods.sort
      puts error.http.inspect
      # raise
    end

    puts "\n"
    puts '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'+"\n"
    @result = response

  end

  def queries
    @list = Query.where(:model_class => 'Vehicle').first.nil?? '' : Query.where(:model_class => 'Vehicle').first.query
    render 'admin/query'
  end

  def send_query_vehicles
    @result = RestClient.get "http://10.0.0.102/queries/vehicles.php"
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

  def send_query_people
    @result = RestClient.get "http://10.0.0.102/queries/people.php"
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
