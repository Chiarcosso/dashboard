class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :query_params, only: [:send_query]

  def queries
    @list = Query.where(:model_class => 'Vehicle').first.nil?? '' : Query.where(:model_class => 'Vehicle').first.query
    render 'admin/query'
  end

  def send_query
    @result = RestClient.get "http://10.0.0.102/queries/vehicles.php"
    @result = JSON.parse @result.body
    @results = Array.new
    @result.each do |row|
      row['manufacturer'].gsub!(/\w+/, &:capitalize)
      row['property'].gsub!(/\w+/, &:capitalize)
      row['type'].first.upcase!
      row['vat'].upcase!
      row['plate'].upcase.gsub!('. *','')

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
      plate = VehicleInformation.where(information: row['plate']).order(date: :asc).last
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
