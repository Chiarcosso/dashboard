class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :query_params, only: [:send_query]

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
      plates = VehicleInformation.where(information: row['plate'].upcase.gsub('. *','')).order(date: :asc)
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
        vehicle = Vehicle.create(dismissed: (row['dismissed'] == '0'), mileage: row['mileage'], registration_date: Date.new(row['registrationDate'].to_i,1,1), property: property, model: model)
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
