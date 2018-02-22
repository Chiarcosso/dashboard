class MssqlReference < ApplicationRecord
  resourcify
  require 'tiny_tds'


  belongs_to :local_object, polymorphic: true

  scope :identify, ->(local_object, table, id) { where(local_object: local_object, remote_object_table: table, remote_object_id: id).first }


  def self.update_all
    upsync_vehicles
    upsync_trailers
    upsync_other_vehicles
    upsync_employees
    # update_employees
    # update_companies
  end

  def self.upsync_vehicles(update)

    begin
      special_logger.info("Starting vehicles upsync") if update
      response = "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} - Inizio importazione #{(update ? '' : '(simulata)')}\n"
      client = get_client
      plate = VehicleInformationType.plate
      chassis = VehicleInformationType.chassis
      atc = Company.chiarcosso
      te = Company.transest
      motivo_fuori_parco = VehicleInformationType.find_by(name: 'Motivo fuori parco')
      motivo_fuori_parco = VehicleInformationType.create(name: 'Motivo fuori parco') if motivo_fuori_parco.nil?
      posti_a_sedere = VehicleInformationType.find_by(name: 'Posti a sedere')
      posti_a_sedere = VehicleInformationType.create(name: 'Posti a sedere') if posti_a_sedere.nil?
      @vehicles = Array.new
      @errors = Array.new
      query = "select 'Veicoli' as table_name, idveicolo as id, targa as plate, telaio as chassis, "\
                  "Tipo.Tipodiveicolo as type, ditta as property, marca as manufacturer, "\
                  "modello as model, modello2 as registration_model, codice_lavaggio as carwash_code, "\
                  "circola as notdismissed, tipologia.[tipologia semirimorchio] as typology, KmAttuali as mileage, "\
                  "ISNULL(convert(nvarchar, data_immatricolazione,126),convert(nvarchar,ISNULL(anno,1900))+'-01-01') as registration_date, categoria as category, motivo_fuori_parco "\
                  "from veicoli "\
                  "left join Tipo on veicoli.IDTipo = Tipo.IDTipo "\
                  "left join [Tipologia rimorchio/semirimorchio] tipologia on veicoli.Id_Tipologia = tipologia.ID "\
                  "where marca is not null and marca != '' and modello is not null and modello != '' "\
                  "and ditta is not null and ditta != '' and marca != 'Targa' and targa is not null and targa != '' "\
                  "order by targa"
      list = client.execute(query)

      special_logger.info("#{list.count} records found")
      special_logger.info(query)
      response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} - Trovati #{list.count} record nella tabella Veicoli, dove targa, marca, modello e ditta sono compilati.\n"
      list.each do |r|
        @error = nil
        vehicle_equipments = Array.new
        vehicle_type = VehicleType.find_by(:name => r['type'])
        if vehicle_type.nil?
          @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle type: #{r['type']}"
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Tipo non valido: #{r['type']}</span>\n"
          special_logger.error(@error)
        end
        property = atc if r['property'] == 'A'
        property = te if r['property'] == 'T'
        if property.nil?
          @error = " #{r['plate']} (#{r['id']}) - Invalid property: #{r['property']}"
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Proprietà non valida: #{r['property']}</span>\n"
          special_logger.error(@error)
        end
        manufacturer = Company.find_by(:name => r['manufacturer'])
        if manufacturer.nil?
          @error = " #{r['plate']} (#{r['id']}) - Invalid manufacturer: #{r['manufacturer']}"
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Produttore non valido: #{r['manufacturer']}</span>\n"
          special_logger.error(@error)
        end
        model = VehicleModel.where(:name => r['model'], :manufacturer => manufacturer).first
        if model.nil?
          @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle model: #{r['manufacturer']} #{r['model']}"
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Modello non valido: #{r['manufacturer']} #{r['model']}</span>\n"
          special_logger.error(@error)
        end
        registration_model = r['registration_model']
        if r['notdismissed'] == false
          dismissed = true
        else
          dismissed = false
        end
        if r['typology'] == '' or r['typology'] == 'NULL' or r['typology'].nil?
          vehicle_typology = VehicleTypology.not_available
        else
          if r['typology'] == 'Scarrabile con caricatore'
            vehicle_typology = VehicleTypology.find_by(:name => 'Scarrabile con gancio')
            vehicle_equipments << VehicleEquipment.find_by(name: 'Caricatore')
          else
            vehicle_typology = VehicleTypology.find_by(:name => r['typology'])
          end
          if vehicle_typology.nil?
            @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle typology: #{r['typology']}"
            response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Tipologia non valida: #{r['typology']}</span>\n"
            special_logger.error(@error)
          end
        end
        mileage = r['mileage'].to_i
        begin
          registration_date = DateTime.parse(r['registration_date']) unless r['registration_date'].nil?
        rescue
          @error = " #{r['plate']} (#{r['id']}) - Invalid Registration date: #{r['registration_date']}"
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Data immatricolazione non valida: #{r['registration_date']}</span>\n"
          special_logger.error(@error)
        end
        if r['category'] == '' or r['category'] == 'NULL' or r['category'].nil?
          vehicle_category = VehicleCategory.not_available
        else
          vehicle_category = VehicleCategory.find_by(:name => r['category'])
          if vehicle_category.nil?
            @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle category: #{r['category']}"
            response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Categoria non valida: #{r['category']}</span>\n"
            special_logger.error(@error)
          end
        end
        if r['carwash_code'].nil? or r['carawash_code'] == ''
          r['carwash_code'] = carwash_code = 'N/D'
        else
          r['carwash_code'] = carwash_code = Vehicle.carwash_codes.key(r['carwash_code'].to_i)
        end
        if r['plate'].nil?
          @error = " #{r['plate']} (#{r['id']}) - Blank plate"
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Targa mancante</span>\n"
          special_logger.error(@error)
        else
          v = Vehicle.find_by_plate(r['plate'].tr('. *',''))
        end
        begin
          if @error.nil?
            if v.nil?
              if update
                v = Vehicle.create(vehicle_type: vehicle_type, property: property, model: model, registration_model: r['registration_model'], dismissed: dismissed, vehicle_typology: vehicle_typology, mileage: mileage, registration_date: registration_date, vehicle_category: vehicle_category, carwash_code: carwash_code)
              else
                v = Vehicle.new
                v.id = 0
              end

              special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Created (id: #{v.id}).")
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Creato (id: #{v.id}).\n"
              special_logger.info("vehicle_type: #{vehicle_type.name}, property: #{property.name}, model: #{model.complete_name}, registration_model: #{registration_model}, dismissed: #{dismissed.to_s}, vehicle_typology: #{vehicle_typology.name}, mileage: #{mileage}, registration_date: #{registration_date.strftime("%d/%m/%Y")}, vehicle_category: #{vehicle_category.name}.")
              response += "tipo: #{vehicle_type.name}, proprietà: #{property.name}, modello: #{model.complete_name}, modello libretto: #{registration_model}, dismesso: #{dismissed.to_s}, tipologia: #{vehicle_typology.name}, chilometraggio: #{mileage}, data immatricolazione: #{registration_date.nil?? '' : registration_date.strftime("%d/%m/%Y")}, categoria: #{vehicle_category.name}.\n"

              VehicleInformation.create(vehicle: v, vehicle_information_type: plate, information: r['plate'].tr('. *','').upcase, date: registration_date) if update

              VehicleInformation.create(vehicle: v, vehicle_information_type: chassis, information: r['chassis'].tr('. *','').upcase, date: registration_date) unless r['chassis'].to_s == '' if update
              special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Chassis added -> #{r['chassis']} (id: #{v.id}).")
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto telaio -> #{r['chassis']} (id: #{v.id}).\n"

              vehicle_equipments.each do |e|
                v.vehicle_equipments << e if update
              end
              if vehicle_equipments.size > 0
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Attrezzatura: #{vehicle_equipments.pluck(:name).join(', ')}.\n"
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Equipment: #{vehicle_equipments.pluck(:name).join(', ')}.")
              end

              unless v.carwash_code == 'N/D' or v.carwash_code.nil?
                cwc = CarwashVehicleCode.createUnique v if update
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunta tessera lavaggio: #{cwc.to_s}.\n"
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Carwash code added: #{cwc.to_s}.")
              end

              mssqlref = MssqlReference.create(local_object: v, remote_object_table: 'Veicoli', remote_object_id: r['id'].to_i) if update
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
              special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")

            elsif v.check_properties(r)

              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - A posto (id: #{v.id}).\n"
              if v.carwash_vehicle_code.nil? and v.carwash_code == 'N/D'
                cwc = CarwashVehicleCode.createUnique v if update
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunta tessera lavaggio: #{cwc.to_s}.\n"
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Carwash code added: #{cwc.to_s}.")
              end
              unless v.has_reference?('Veicoli',r['id'])
                mssqlref = MssqlReference.create(local_object: v, remote_object_table: 'Veicoli', remote_object_id: r['id'].to_i) if update
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")
              end
            else

              special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Updated (id: #{v.id}).")
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiornato (id: #{v.id}).\n"
              special_logger.info("Dashboard - vehicle_type: #{v.vehicle_type.name}, property: #{v.property.name}, model: #{v.model.complete_name}, registration_model: #{v.registration_model}, dismissed: #{v.dismissed.to_s}, vehicle_typology: #{v.vehicle_typology.name}, mileage: #{v.mileage}, registration_date: #{v.registration_date.nil?? '' : v.registration_date.strftime("%d/%m/%Y")}, vehicle_category: #{v.vehicle_category.name}, carwash_code: #{v.carwash_code}.")
              response += "Dashboard - tipo: #{v.vehicle_type.name}, proprietà: #{v.property.name}, modello: #{v.model.complete_name}, modello libretto: #{v.registration_model}, dismesso: #{v.dismissed.to_s}, tipologia: #{v.vehicle_typology.name}, chilometraggio: #{v.mileage}, data immatricolazione: #{v.registration_date.nil?? '' : v.registration_date.strftime("%d/%m/%Y")}, categoria: #{v.vehicle_category.name}, codice_lavaggio: #{v.carwash_code}.\n"
              v.update(vehicle_type: vehicle_type, property: property, model: model, registration_model: r['registration_model'], dismissed: dismissed, vehicle_typology: vehicle_typology, mileage: mileage, registration_date: registration_date, vehicle_category: vehicle_category, carwash_code: carwash_code) if update
              special_logger.info("Access - vehicle_type: #{vehicle_type.name}, property: #{property.name}, model: #{model.complete_name}, registration_model: #{registration_model}, dismissed: #{dismissed.to_s}, vehicle_typology: #{vehicle_typology.name}, mileage: #{mileage}, registration_date: #{registration_date.strftime("%d/%m/%Y")}, vehicle_category: #{vehicle_category.name}, carwash_code: #{carwash_code}.")
              response += "Access - tipo: #{vehicle_type.name}, proprietà: #{property.name}, modello: #{model.complete_name}, modello libretto: #{registration_model}, dismesso: #{dismissed.to_s}, tipologia: #{vehicle_typology.name}, chilometraggio: #{mileage}, data immatricolazione: #{registration_date.strftime("%d/%m/%Y")}, categoria: #{vehicle_category.name}, codice_lavaggio: #{carwash_code}.\n"

              if v.find_information(chassis).nil?
                VehicleInformation.create(vehicle: v, vehicle_information_type: chassis, information: r['chassis'].tr('. *','').upcase, date: registration_date) if update
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Chassis added -> #{r['chassis']} (id: #{v.id}).")
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto telaio -> #{r['chassis']} (id: #{v.id}).\n"
              end
              v.vehicle_equipments.clear if update
              vehicle_equipments.each do |e|
                v.vehicle_equipments << e if update
              end
              if vehicle_equipments.size > 0
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Attrezzatura: #{vehicle_equipments.pluck(:name).join(', ')}.\n"
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Equipment: #{vehicle_equipments.pluck(:name).join(', ')}.")
              end
              if v.carwash_vehicle_code.nil? and v.carwash_code == 'N/D'
                cwc = CarwashVehicleCode.createUnique v if update
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunta tessera lavaggio: #{cwc.to_s}.\n"
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Carwash code added: #{cwc.to_s}.")
              end
              unless v.has_reference?('Veicoli',r['id'])
                mssqlref = MssqlReference.create(local_object: v, remote_object_table: 'Veicoli', remote_object_id: r['id'].to_i) if update
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")
              end
            end
          end
        rescue Exception => e
          special_logger.error("  - #{r['plate']} (#{r['id']}) #{e.message}\n#{e.backtrace}")
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} -  -> #{r['plate']} (#{r['id']}) #{e.message}\n#{e.backtrace}</span>\n"

        end
      end
    rescue Exception => e
      special_logger.error("#{e.message}\n#{e.backtrace}")
      response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} - #{e.message}\n#{e.backtrace}</span>\n"

    end

    return {response: response, array: [] }
  end

  def self.upsync_trailers(update)
    begin
      special_logger.info("Starting trailers upsync") if update
      response = "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} - Inizio importazione #{(update ? '' : '(simulata)')}\n"
      client = get_client
      plate = VehicleInformationType.plate
      chassis = VehicleInformationType.chassis
      atc = Company.chiarcosso
      te = Company.transest
      motivo_fuori_parco = VehicleInformationType.find_by(name: 'Motivo fuori parco')
      motivo_fuori_parco = VehicleInformationType.create(name: 'Motivo fuori parco') if motivo_fuori_parco.nil?
      @vehicles = Array.new
      @errors = Array.new
      query = "select 'Rimorchi1' as table_name, idrimorchio as id, targa as plate, telaio as chassis, "\
                  "(case Tipo when 'S' then 'Semirimorchio' when 'R' then 'Rimorchio' end) as type, ditta as property, "\
                  "marca as manufacturer, (case Tipo when 'S' then 'Semirimorchio' when 'R' then 'Rimorchio' end) as model, "\
                  "(case Tipo when 'S' then 'Semirimorchio' when 'R' then 'Rimorchio' end) as registration_model, "\
                  "codice_lavaggio as carwash_code, circola as notdismissed, "\
                  "tipologia.[tipologia semirimorchio] as typology, Km as mileage, "\
                  "ISNULL(convert(nvarchar, data_immatricolazione,126),convert(nvarchar,ISNULL(anno,1900))+'-01-01') as registration_date, "\
                  "categoria as category, motivo_fuori_parco "\
                  "from rimorchi1 "\
                  "left join [Tipologia rimorchio/semirimorchio] tipologia on rimorchi1.[Tipologia Rimonchio/Semirimorchio] = tipologia.ID "\
                  "where marca is not null and marca != '' and tipo is not null and tipo != '' "\
                  "and ditta is not null and ditta != '' and marca != 'Targa' and targa is not null and targa != '' "\
                  "order by targa"
      list = client.execute(query)

      special_logger.info("#{list.count} records found")
      special_logger.info(query)
      response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} - Trovati #{list.count} record nella tabella Rimorchi1, dove targa, marca, tipo e ditta sono compilati.\n"
      list.each do |r|
        @error = nil
        vehicle_equipments = Array.new
        vehicle_type = VehicleType.find_by(:name => r['type'])
        if vehicle_type.nil?
          @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle type: #{r['type']}"
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Tipo non valido: #{r['type']}</span>\n"
          special_logger.error(@error)
        end
        property = atc if r['property'] == 'A'
        property = te if r['property'] == 'T'
        if property.nil?
          @error = " #{r['plate']} (#{r['id']}) - Invalid property: #{r['property']}"
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Proprietà non valida: #{r['property']}</span>\n"
          special_logger.error(@error)
        end
        manufacturer = Company.find_by(:name => r['manufacturer'])
        if manufacturer.nil?
          @error = " #{r['plate']} (#{r['id']}) - Invalid manufacturer: #{r['manufacturer']}"
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Produttore non valido: #{r['manufacturer']}</span>\n"
          special_logger.error(@error)
        end
        model = VehicleModel.where(:name => r['model'], :manufacturer => manufacturer).first
        if model.nil?
          @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle model: #{r['manufacturer']} #{r['model']}"
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Modello non valido: #{r['manufacturer']} #{r['model']}</span>\n"
          special_logger.error(@error)
        end
        registration_model = r['registration_model']
        if r['notdismissed'] == false
          dismissed = true
        else
          dismissed = false
        end
        if r['typology'] == '' or r['typology'] == 'NULL' or r['typology'].nil?
          vehicle_typology = VehicleTypology.not_available
        else
          if r['typology'] == 'Scarrabile con caricatore'
            vehicle_typology = VehicleTypology.find_by(:name => 'Scarrabile con gancio')
            vehicle_equipments << VehicleEquipment.find_by(name: 'Caricatore')
          else
            vehicle_typology = VehicleTypology.find_by(:name => r['typology'])
          end
          if vehicle_typology.nil?
            @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle typology: #{r['typology']}"
            response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Tipologia non valida: #{r['typology']}</span>\n"
            special_logger.error(@error)
          end
        end
        mileage = r['mileage'].to_i
        begin
          registration_date = DateTime.parse(r['registration_date']) unless r['registration_date'].nil?
        rescue
          @error = " #{r['plate']} (#{r['id']}) - Invalid Registration date: #{r['registration_date']}"
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Data immatricolazione non valida: #{r['registration_date']}</span>\n"
          special_logger.error(@error)
        end
        if r['category'] == '' or r['category'] == 'NULL' or r['category'].nil?
          vehicle_category = VehicleCategory.not_available
        else
          vehicle_category = VehicleCategory.find_by(:name => r['category'])
          if vehicle_category.nil?
            @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle category: #{r['category']}"
            response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Categoria non valida: #{r['category']}</span>\n"
            special_logger.error(@error)
          end
        end
        if r['carwash_code'].nil? or r['carawash_code'] == ''
          r['carwash_code'] = carwash_code = 'N/D'
        else
          r['carwash_code'] = carwash_code = Vehicle.carwash_codes.key(r['carwash_code'].to_i)
        end
        if r['plate'].nil?
          @error = " #{r['plate']} (#{r['id']}) - Blank plate"
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Targa mancante</span>\n"
          special_logger.error(@error)
        else
          v = Vehicle.find_by_plate(r['plate'].tr('. *',''))
        end
        begin
          if @error.nil?
            if v.nil?
              if update
                v = Vehicle.create(vehicle_type: vehicle_type, property: property, model: model, registration_model: r['registration_model'], dismissed: dismissed, vehicle_typology: vehicle_typology, mileage: mileage, registration_date: registration_date, vehicle_category: vehicle_category, carwash_code: carwash_code)
              else
                v = Vehicle.new
                v.id = 0
              end

              special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Created (id: #{v.id}).")
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Creato (id: #{v.id}).\n"
              special_logger.info("vehicle_type: #{vehicle_type.name}, property: #{property.name}, model: #{model.complete_name}, registration_model: #{registration_model}, dismissed: #{dismissed.to_s}, vehicle_typology: #{vehicle_typology.name}, mileage: #{mileage}, registration_date: #{registration_date.strftime("%d/%m/%Y")}, vehicle_category: #{vehicle_category.name}.")
              response += "tipo: #{vehicle_type.name}, proprietà: #{property.name}, modello: #{model.complete_name}, modello libretto: #{registration_model}, dismesso: #{dismissed.to_s}, tipologia: #{vehicle_typology.name}, chilometraggio: #{mileage}, data immatricolazione: #{registration_date.strftime("%d/%m/%Y")}, categoria: #{vehicle_category.name}.\n"

              VehicleInformation.create(vehicle: v, vehicle_information_type: plate, information: r['plate'].tr('. *','').upcase, date: registration_date) if update

              VehicleInformation.create(vehicle: v, vehicle_information_type: chassis, information: r['chassis'].tr('. *','').upcase, date: registration_date) unless r['chassis'].to_s == '' if update
              special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Chassis added -> #{r['chassis']} (id: #{v.id}).")
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto telaio -> #{r['chassis']} (id: #{v.id}).\n"

              vehicle_equipments.each do |e|
                v.vehicle_equipments << e if update
              end
              if vehicle_equipments.size > 0
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Attrezzatura: #{vehicle_equipments.pluck(:name).join(', ')}.\n"
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Equipment: #{vehicle_equipments.pluck(:name).join(', ')}.")
              end
              if v.find_information(motivo_fuori_parco).nil?
                unless r['motivo_fuori_parco'].nil? or r['motivo_fuori_parco'] == ''
                  VehicleInformation.create(vehicle: v, vehicle_information_type: motivo_fuori_parco, information: r['motivo_fuori_parco'], date: registration_date) unless r['posti_a_sedere'].to_s == '' if update
                  special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Dismission cause added -> #{r['motivo_fuori_parco']} (id: #{v.id}).")
                  response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto motivo fuori parco -> #{r['motivo_fuori_parco']} (id: #{v.id}).\n"
                end
              end
              if v.carwash_vehicle_code.nil? and v.carwash_code == 'N/D'
                cwc = CarwashVehicleCode.createUnique v if update
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunta tessera lavaggio: #{cwc.to_s}.\n"
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Carwash code added: #{cwc.to_s}.")
              end
              mssqlref = MssqlReference.create(local_object: v, remote_object_table: 'Rimorchi1', remote_object_id: r['id'].to_i) if update
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
              special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")

            elsif v.check_properties(r)

              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - A posto (id: #{v.id}).\n"
              if v.find_information(motivo_fuori_parco).nil?
                unless r['motivo_fuori_parco'].nil? or r['motivo_fuori_parco'] == ''
                  VehicleInformation.create(vehicle: v, vehicle_information_type: motivo_fuori_parco, information: r['motivo_fuori_parco'], date: registration_date) unless r['posti_a_sedere'].to_s == '' if update
                  special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Dismission cause added -> #{r['motivo_fuori_parco']} (id: #{v.id}).")
                  response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto motivo fuori parco -> #{r['motivo_fuori_parco']} (id: #{v.id}).\n"
                end
              end
              if v.carwash_vehicle_code.nil? and v.carwash_code == 'N/D'
                cwc = CarwashVehicleCode.createUnique v if update
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunta tessera lavaggio: #{cwc.to_s}.\n"
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Carwash code added: #{cwc.to_s}.")
              end
              unless v.has_reference?('Rimorchi1',r['id'])
                mssqlref = MssqlReference.create(local_object: v, remote_object_table: 'Rimorchi1', remote_object_id: r['id'].to_i) if update
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")
              end
            else

              special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Updated (id: #{v.id}).")
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiornato (id: #{v.id}).\n"
              special_logger.info("Dashboard - vehicle_type: #{v.vehicle_type.name}, property: #{v.property.name}, model: #{v.model.complete_name}, registration_model: #{v.registration_model}, dismissed: #{v.dismissed.to_s}, vehicle_typology: #{v.vehicle_typology.name}, mileage: #{v.mileage}, registration_date: #{v.registration_date.nil?? '' : v.registration_date.strftime("%d/%m/%Y")}, vehicle_category: #{v.vehicle_category.name}, carwash_code: #{v.carwash_code}.")
              response += "Dashboard - tipo: #{v.vehicle_type.name}, proprietà: #{v.property.name}, modello: #{v.model.complete_name}, modello libretto: #{v.registration_model}, dismesso: #{v.dismissed.to_s}, tipologia: #{v.vehicle_typology.name}, chilometraggio: #{v.mileage}, data immatricolazione: #{v.registration_date.nil?? '' : v.registration_date.strftime("%d/%m/%Y")}, categoria: #{v.vehicle_category.name}, codice_lavaggio: #{v.carwash_code}.\n"
              v.update(vehicle_type: vehicle_type, property: property, model: model, registration_model: r['registration_model'], dismissed: dismissed, vehicle_typology: vehicle_typology, mileage: mileage, registration_date: registration_date, vehicle_category: vehicle_category, carwash_code: carwash_code) if update
              special_logger.info("Access - vehicle_type: #{vehicle_type.name}, property: #{property.name}, model: #{model.complete_name}, registration_model: #{registration_model}, dismissed: #{dismissed.to_s}, vehicle_typology: #{vehicle_typology.name}, mileage: #{mileage}, registration_date: #{registration_date.strftime("%d/%m/%Y")}, vehicle_category: #{vehicle_category.name}, carwash_code: #{carwash_code}.")
              response += "Access - tipo: #{vehicle_type.name}, proprietà: #{property.name}, modello: #{model.complete_name}, modello libretto: #{registration_model}, dismesso: #{dismissed.to_s}, tipologia: #{vehicle_typology.name}, chilometraggio: #{mileage}, data immatricolazione: #{registration_date.strftime("%d/%m/%Y")}, categoria: #{vehicle_category.name}, codice_lavaggio: #{carwash_code}.\n"

              if v.find_information(chassis).nil?
                VehicleInformation.create(vehicle: v, vehicle_information_type: chassis, information: r['chassis'].tr('. *','').upcase, date: registration_date) if update
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Chassis added -> #{r['chassis']} (id: #{v.id}).")
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto telaio -> #{r['chassis']} (id: #{v.id}).\n"
              end
              v.vehicle_equipments.clear if update
              vehicle_equipments.each do |e|
                v.vehicle_equipments << e if update
              end
              if vehicle_equipments.size > 0
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Attrezzatura: #{vehicle_equipments.pluck(:name).join(', ')}.\n"
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Equipment: #{vehicle_equipments.pluck(:name).join(', ')}.")
              end
              if v.find_information(motivo_fuori_parco).nil?
                unless r['motivo_fuori_parco'].nil? or r['motivo_fuori_parco'] == ''
                  VehicleInformation.create(vehicle: v, vehicle_information_type: motivo_fuori_parco, information: r['motivo_fuori_parco'], date: registration_date) unless r['posti_a_sedere'].to_s == '' if update
                  special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Dismission cause added -> #{r['motivo_fuori_parco']} (id: #{v.id}).")
                  response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto motivo fuori parco -> #{r['motivo_fuori_parco']} (id: #{v.id}).\n"
                end
              end
              if v.carwash_vehicle_code.nil? and v.carwash_code == 'N/D'
                cwc = CarwashVehicleCode.createUnique v if update
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunta tessera lavaggio: #{cwc.to_s}.\n"
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Carwash code added: #{cwc.to_s}.")
              end
              unless v.has_reference?('Rimorchi1',r['id'])
                mssqlref = MssqlReference.create(local_object: v, remote_object_table: 'Rimorchi1', remote_object_id: r['id'].to_i) if update
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")
              end
            end
          end
        rescue Exception => e
          special_logger.error("  - #{r['plate']} (#{r['id']}) #{e.message}\n#{e.backtrace}")
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} -  -> #{r['plate']} (#{r['id']}) #{e.message}\n#{e.backtrace}\n</span>"

        end
      end
    rescue Exception => e
      special_logger.error("#{e.message}\n#{e.backtrace}")
      response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} - #{e.message}\n#{e.backtrace}</span>\n"

    end

    return {response: response, array: [] }
  end

  def self.upsync_other_vehicles(update)
    begin
      special_logger.info("Starting other_vehicles upsync") if update
      response = "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} - Inizio importazione #{(update ? '' : '(simulata)')}\n"
      client = get_client
      plate = VehicleInformationType.plate
      chassis = VehicleInformationType.chassis
      atc = Company.chiarcosso
      te = Company.transest
      ec = Company.edilizia
      motivo_fuori_parco = VehicleInformationType.find_by(name: 'Motivo fuori parco')
      motivo_fuori_parco = VehicleInformationType.create(name: 'Motivo fuori parco') if motivo_fuori_parco.nil?
      posti_a_sedere = VehicleInformationType.find_by(name: 'Posti a sedere')
      posti_a_sedere = VehicleInformationType.find_by(name: 'Posti a sedere') if posti_a_sedere.nil?
      @vehicles = Array.new
      @errors = Array.new
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
                  "where marca is not null and marca != '' and tipo is not null and tipo != '' "\
                  "and ditta is not null and ditta != '' and marca != 'Targa' and modello is not null and modello != '' and targa is not null and targa != '' "\
                  "order by targa"
      list = client.execute(query)

      special_logger.info("#{list.count} records found")
      special_logger.info(query)
      response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} - Trovati #{list.count} record nella tabella Altri mezzi, dove targa, marca, modello, tipo e ditta sono compilati.\n"
      list.each do |r|
        @error = nil
        vehicle_equipments = Array.new
        vehicle_type = VehicleType.find_by(:name => r['type'])
        if vehicle_type.nil?
          @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle type: #{r['type']}"
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Tipo non valido: #{r['type']}</span>\n"
          special_logger.error(@error)
        end
        property = atc if r['property'] == 'A'
        property = te if r['property'] == 'T'
        property = ec if r['property'] == 'E'
        if property.nil?
          @error = " #{r['plate']} (#{r['id']}) - Invalid property: #{r['property']}"
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Proprietà non valida: #{r['property']}</span>\n"
          special_logger.error(@error)
        end
        manufacturer = Company.find_by(:name => r['manufacturer'])
        if manufacturer.nil?
          @error = " #{r['plate']} (#{r['id']}) - Invalid manufacturer: #{r['manufacturer']}"
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Produttore non valido: #{r['manufacturer']}</span>\n"
          special_logger.error(@error)
        end
        serie = nil
        if r['model'] =~ /\d serie$/
          serie = r['model'][/(\d) serie$/,1].to_i
          r['model'] = r['model'][/^(.*) \d serie$/,1]
        end

        model = VehicleModel.where(:name => r['model'], :manufacturer => manufacturer).first
        if model.nil?
          @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle model: #{r['manufacturer']} #{r['model']}"
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Modello non valido: #{r['manufacturer']} #{r['model']}</span>\n"
          special_logger.error(@error)
        end
        registration_model = r['registration_model']
        if r['notdismissed'] == false
          dismissed = true
        else
          dismissed = false
        end
        if r['typology'] == '' or r['typology'] == 'NULL' or r['typology'].nil?
          vehicle_typology = VehicleTypology.not_available
        else
          if r['typology'] == 'Scarrabile con caricatore'
            vehicle_typology = VehicleTypology.find_by(:name => 'Scarrabile con gancio')
            vehicle_equipments << VehicleEquipment.find_by(name: 'Caricatore')
          else
            vehicle_typology = VehicleTypology.find_by(:name => r['typology'])
          end
          if vehicle_typology.nil?
            @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle typology: #{r['typology']}"
            response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Tipologia non valida: #{r['typology']}</span>\n"
            special_logger.error(@error)
          end
        end
        mileage = r['mileage'].to_i
        begin
          registration_date = DateTime.parse(r['registration_date']) unless r['registration_date'].nil?
        rescue
          @error = " #{r['plate']} (#{r['id']}) - Invalid Registration date: #{r['registration_date']}"
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Data immatricolazione non valida: #{r['registration_date']}</span>\n"
          special_logger.error(@error)
        end
        if r['category'] == '' or r['category'] == 'NULL' or r['category'].nil?
          vehicle_category = VehicleCategory.not_available
        else
          vehicle_category = VehicleCategory.find_by(:name => r['category'])
          if vehicle_category.nil?
            @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle category: #{r['category']}"
            response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Categoria non valida: #{r['category']}</span>\n"
            special_logger.error(@error)
          end
        end
        if r['carwash_code'].nil? or r['carawash_code'] == ''
          r['carwash_code'] = carwash_code = 'N/D'
        else
          r['carwash_code'] = carwash_code = Vehicle.carwash_codes.key(r['carwash_code'].to_i)
        end
        if r['plate'].nil?
          @error = " #{r['plate']} (#{r['id']}) - Blank plate"
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Targa mancante</span>\n"
          special_logger.error(@error)
        else
          v = Vehicle.find_by_plate(r['plate'].tr('. *',''))
        end
        begin
          if @error.nil?
            if v.nil? #Vehicle does not exist
              if update
                v = Vehicle.create(vehicle_type: vehicle_type, property: property, model: model, registration_model: r['registration_model'], serie: serie, dismissed: dismissed, vehicle_typology: vehicle_typology, mileage: mileage, registration_date: registration_date, vehicle_category: vehicle_category, carwash_code: carwash_code)
              else
                v = Vehicle.new
                v.id = 0
              end

              special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Created (id: #{v.id}).")
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Creato (id: #{v.id}).\n"
              special_logger.info("vehicle_type: #{vehicle_type.name}, property: #{property.name}, model: #{model.complete_name}, registration_model: #{registration_model}, serie: #{serie}, dismissed: #{dismissed.to_s}, vehicle_typology: #{vehicle_typology.name}, mileage: #{mileage}, registration_date: #{registration_date.strftime("%d/%m/%Y")}, vehicle_category: #{vehicle_category.name}.")
              response += "tipo: #{vehicle_type.name}, proprietà: #{property.name}, modello: #{model.complete_name}, modello libretto: #{registration_model}, serie: #{serie}, dismesso: #{dismissed.to_s}, tipologia: #{vehicle_typology.name}, chilometraggio: #{mileage}, data immatricolazione: #{registration_date.strftime("%d/%m/%Y")}, categoria: #{vehicle_category.name}.\n"

              VehicleInformation.create(vehicle: v, vehicle_information_type: plate, information: r['plate'].tr('. *','').upcase, date: registration_date) if update


              unless r['chassis'].nil? or r['chassis'] == ''
                VehicleInformation.create(vehicle: v, vehicle_information_type: chassis, information: r['chassis'].tr('. *','').upcase, date: registration_date) unless r['chassis'].to_s == '' if update
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Chassis added -> #{r['chassis']} (id: #{v.id}).")
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto telaio -> #{r['chassis']} (id: #{v.id}).\n"
              end
              unless r['posti_a_sedere'].nil? or r['posti_a_sedere'] == ''
                VehicleInformation.create(vehicle: v, vehicle_information_type: posti_a_sedere, information: r['posti_a_sedere'], date: registration_date) unless r['posti_a_sedere'].to_s == '' if update
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Seat number added -> #{r['posti_a_sedere']} (id: #{v.id}).")
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto nr. posti a sedere -> #{r['posti_a_sedere']} (id: #{v.id}).\n"
              end
              unless r['motivo_fuori_parco'].nil? or r['motivo_fuori_parco'] == ''
                VehicleInformation.create(vehicle: v, vehicle_information_type: motivo_fuori_parco, information: r['motivo_fuori_parco'], date: registration_date) unless r['posti_a_sedere'].to_s == '' if update
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Dismission cause added -> #{r['motivo_fuori_parco']} (id: #{v.id}).")
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto motivo fuori parco -> #{r['motivo_fuori_parco']} (id: #{v.id}).\n"
              end



              vehicle_equipments.each do |e|
                v.vehicle_equipments << e if update
              end
              if vehicle_equipments.size > 0
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Attrezzatura: #{vehicle_equipments.pluck(:name).join(', ')}.\n"
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Equipment: #{vehicle_equipments.pluck(:name).join(', ')}.")
              end

              if v.carwash_vehicle_code.nil? and v.carwash_code == 'N/D'
                cwc = CarwashVehicleCode.createUnique v if update
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunta tessera lavaggio: #{cwc.to_s}.\n"
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Carwash code added: #{cwc.to_s}.")
              end

              mssqlref = MssqlReference.create(local_object: v, remote_object_table: '[Altri mezzi]', remote_object_id: r['id'].to_i) if update
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
              special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")

            elsif v.check_properties(r)  #Vehicle exists and has the same properties as the importing one

              if v.carwash_vehicle_code.nil? and v.carwash_code == 'N/D'
                cwc = CarwashVehicleCode.createUnique v if update
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunta tessera lavaggio: #{cwc.to_s}.\n"
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Carwash code added: #{cwc.to_s}.")
              end
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - A posto (id: #{v.id}).\n"
              unless v.has_reference?('[Altri mezzi]',r['id'])
                mssqlref = MssqlReference.create(local_object: v, remote_object_table: '[Altri mezzi]', remote_object_id: r['id'].to_i) if update
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")
              end
              if v.find_information(posti_a_sedere).nil?
                unless r['posti_a_sedere'].nil? or r['posti_a_sedere'] == ''
                  VehicleInformation.create(vehicle: v, vehicle_information_type: posti_a_sedere, information: r['posti_a_sedere'], date: registration_date) unless r['posti_a_sedere'].to_s == '' if update
                  special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Seat number added -> #{r['posti_a_sedere']} (id: #{v.id}).")
                  response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto nr. posti a sedere -> #{r['posti_a_sedere']} (id: #{v.id}).\n"
                end
              end
              if v.find_information(motivo_fuori_parco).nil?
                unless r['motivo_fuori_parco'].nil? or r['motivo_fuori_parco'] == ''
                  VehicleInformation.create(vehicle: v, vehicle_information_type: motivo_fuori_parco, information: r['motivo_fuori_parco'], date: registration_date) unless r['posti_a_sedere'].to_s == '' if update
                  special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Dismission cause added -> #{r['motivo_fuori_parco']} (id: #{v.id}).")
                  response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto motivo fuori parco -> #{r['motivo_fuori_parco']} (id: #{v.id}).\n"
                end
              end
            else #Vehicle exists but has not the same properties as the importing one


              special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Updated (id: #{v.id}).")
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiornato (id: #{v.id}).\n"
              special_logger.info("Dashboard - vehicle_type: #{v.vehicle_type.name}, property: #{v.property.name}, model: #{v.model.complete_name}, registration_model: #{v.registration_model}, serie: #{serie}, dismissed: #{v.dismissed.to_s}, vehicle_typology: #{v.vehicle_typology.name}, mileage: #{v.mileage}, registration_date: #{v.registration_date.nil?? '' : v.registration_date.strftime("%d/%m/%Y")}, vehicle_category: #{v.vehicle_category.name}, carwash_code: #{v.carwash_code}.")
              response += "Dashboard - tipo: #{v.vehicle_type.name}, proprietà: #{v.property.name}, modello: #{v.model.complete_name}, modello libretto: #{v.registration_model}, serie: #{serie}, dismesso: #{v.dismissed.to_s}, tipologia: #{v.vehicle_typology.name}, chilometraggio: #{v.mileage}, data immatricolazione: #{v.registration_date.nil?? '' : v.registration_date.strftime("%d/%m/%Y")}, categoria: #{v.vehicle_category.name}, codice_lavaggio: #{v.carwash_code}.\n"
              v.update(vehicle_type: vehicle_type, property: property, model: model, registration_model: r['registration_model'], serie: serie, dismissed: dismissed, vehicle_typology: vehicle_typology, mileage: mileage, registration_date: registration_date, vehicle_category: vehicle_category, carwash_code: carwash_code) if update
              special_logger.info("Access - vehicle_type: #{vehicle_type.name}, property: #{property.name}, model: #{model.complete_name}, registration_model: #{registration_model}, serie: #{serie}, dismissed: #{dismissed.to_s}, vehicle_typology: #{vehicle_typology.name}, mileage: #{mileage}, registration_date: #{registration_date.strftime("%d/%m/%Y")}, vehicle_category: #{vehicle_category.name}, carwash_code: #{carwash_code}.")
              response += "Access - tipo: #{vehicle_type.name}, proprietà: #{property.name}, modello: #{model.complete_name}, modello libretto: #{registration_model}, serie: #{serie}, dismesso: #{dismissed.to_s}, tipologia: #{vehicle_typology.name}, chilometraggio: #{mileage}, data immatricolazione: #{registration_date.strftime("%d/%m/%Y")}, categoria: #{vehicle_category.name}, codice_lavaggio: #{carwash_code}.\n"

              if v.find_information(chassis).nil?
                VehicleInformation.create(vehicle: v, vehicle_information_type: chassis, information: r['chassis'].tr('. *','').upcase, date: registration_date) if update
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Chassis added -> #{r['chassis']} (id: #{v.id}).")
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto telaio -> #{r['chassis']} (id: #{v.id}).\n"
              end
              v.vehicle_equipments.clear if update
              vehicle_equipments.each do |e|
                v.vehicle_equipments << e if update
              end
              if vehicle_equipments.size > 0
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Attrezzatura: #{vehicle_equipments.pluck(:name).join(', ')}.\n"
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Equipment: #{vehicle_equipments.pluck(:name).join(', ')}.")
              end
              if v.find_information(posti_a_sedere).nil?
                unless r['posti_a_sedere'].nil? or r['posti_a_sedere'] == ''
                  VehicleInformation.create(vehicle: v, vehicle_information_type: posti_a_sedere, information: r['posti_a_sedere'], date: registration_date) unless r['posti_a_sedere'].to_s == '' if update
                  special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Seat number added -> #{r['posti_a_sedere']} (id: #{v.id}).")
                  response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto nr. posti a sedere -> #{r['posti_a_sedere']} (id: #{v.id}).\n"
                end
              end
              if v.find_information(motivo_fuori_parco).nil?
                unless r['motivo_fuori_parco'].nil? or r['motivo_fuori_parco'] == ''
                  VehicleInformation.create(vehicle: v, vehicle_information_type: motivo_fuori_parco, information: r['motivo_fuori_parco'], date: registration_date) unless r['posti_a_sedere'].to_s == '' if update
                  special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Dismission cause added -> #{r['motivo_fuori_parco']} (id: #{v.id}).")
                  response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto motivo fuori parco -> #{r['motivo_fuori_parco']} (id: #{v.id}).\n"
                end
              end
              if v.carwash_vehicle_code.nil? and v.carwash_code == 'N/D'
                cwc = CarwashVehicleCode.createUnique v if update
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunta tessera lavaggio: #{cwc.to_s}.\n"
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Carwash code added: #{cwc.to_s}.")
              end
              unless v.has_reference?('[Altri mezzi]',r['id'])
                mssqlref = MssqlReference.create(local_object: v, remote_object_table: '[Altri mezzi]', remote_object_id: r['id'].to_i) if update
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
                special_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")
              end
            end
          end
        rescue Exception => e
          special_logger.error("  - #{r['plate']} (#{r['id']}) #{e.message}\n#{e.backtrace}")
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} -  -> #{r['plate']} (#{r['id']}) #{e.message}\n#{e.backtrace}</span>\n"

        end
      end
    rescue Exception => e
      special_logger.error("#{e.message}\n#{e.backtrace}")
      response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} - #{e.message}\n#{e.backtrace}</span>\n"

    end

    return {response: response, array: [] }
  end

  def self.upsync_employees(update)

    begin
      special_logger.info("Starting vehicles upsync") if update
      response = "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} - Inizio importazione #{(update ? '' : '(simulata)')}\n"
      client = get_client

      atc = Company.chiarcosso
      te = Company.transest
      driver = CompanyRelation.find_by(name: 'Autista')
      driver = CompanyRelation.create(name: 'Autista') if driver.nil?

      @errors = Array.new
      query = "select 'Autisti' as table_name, a.Idautista as id, a.ditta as employer, a.nome as name, a.cognome as surname, "\
                  "Mansione.Descrizione as role, a.attivo as dismissed "\
                  "from Autisti a "\
                  "left join Mansione on a.idmansione = mansione.idmansione "\
                  "where a.ditta is not null and a.ditta != '' and a.nome is not null and a.nome != '' "\
                  "and a.cognome is not null and a.cognome != ''"\
                  "order by a.cognome,a.nome"
      list = client.execute(query)

      special_logger.info("#{list.count} records found")
      special_logger.info(query)
      response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} - Trovati #{list.count} record nella tabella Autisti, dove ditta, nome e cognome sono compilati.\n"
      list.each do |r|
        @error = nil

        employer = atc if r['employer'] == 'A'
        employer = te if r['employer'] == 'T'
        r['name'] = r['name'].strip.titleize
        r['surname'] = r['surname'].strip.titleize

        if employer.nil?
          @error = " #{r['cognome']} #{r['nome']} (#{r['id']}) - Invalid employer: #{r['employer']}"
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['cognome']} #{r['nome']} (#{r['id']}) - Ditta non valida: #{r['employer']}</span>\n"
          special_logger.error(@error)
        end
        if r['notdismissed'] == false
          notdismissed = false
        else
          notdismissed = true
        end

        company_relation = CompanyRelation.find_by(:name => r['role'])
        if company_relation.nil?
          @error = " #{r['cognome']} #{r['nome']} (#{r['id']}) - Invalid company relation: #{r['role']}"
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")}  #{r['cognome']} #{r['nome']} (#{r['id']}) - Mansione non valida: #{r['role']}</span>\n"
          special_logger.error(@error)
        end

        p = Person.find_by(name: r['name'], surname: r['surname'])

        begin
          if @error.nil?
            if p.nil?
              if update
                p = Person.create(name: r['name'], surname: r['surname'])
              else
                p = Person.new(name: r['name'], surname: r['surname'])
                p.id = 0
              end

              special_logger.info(" - #{p.id} ->  #{r['cognome']} #{r['nome']} (#{r['id']}) - Created (id: #{p.id}).")
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")}  #{r['cognome']} #{r['nome']} (#{r['id']}) - Creato (id: #{p.id}).\n"
              special_logger.info("name: #{p.surname} #{p.name}.")
              response += "nome: #{p.name}, cognome: #{p.surname}.\n"

              CompanyPerson.create(person: p, company: employer, company_relation: company_relation, acting: notdismissed) if update
              special_logger.info(" - #{p.id} -> #{p.surname} #{p.name} (#{r['id']}) - CompanyPerson added -> #{employer}: #{r['role']} (id: #{p.id}).")
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{p.surname} #{p.name} (#{r['id']}) - Aggiunto ruolo -> #{employer}: #{r['role']} (id: #{p.id}).\n"

              if company_relation == driver
                cwc = CarwashDriverCode.createUnique p if update
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{p.surname} #{p.name} (#{r['id']}) - Aggiunta tessera lavaggio: #{cwc.to_s}.\n"
                special_logger.info(" - #{p.id} -> #{p.surname} #{p.name} (#{r['id']}) - Carwash code added: #{cwc.to_s}.")
              end

              mssqlref = MssqlReference.create(local_object: p, remote_object_table: 'Autisti', remote_object_id: r['id'].to_i) if update
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{p.surname} #{p.name} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
              special_logger.info(" - #{p.id} -> #{p.surname} #{p.name} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")

            elsif p.check_properties(r)

              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:S")} #{p.surname} #{p.name} (#{r['id']}) - A posto (id: #{p.id}).\n"
              unless p.has_relation?(employer,company_relation)
                CompanyPerson.create(person: p, company: employer, company_relation: company_relation, acting: notdismissed) if update
                special_logger.info(" - #{p.id} -> #{p.surname} #{p.name} (#{r['id']}) - CompanyPerson added -> #{employer}: #{r['role']} -> #{notdismissed ? 'acting' : 'non acting'} (id: #{p.id}).")
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{p.surname} #{p.name} (#{r['id']}) - Aggiunto ruolo -> #{employer}: #{r['role']} -> #{notdismissed ? 'attivo' : 'non attivo'} (id: #{p.id}).\n"
              else
                cr = CompanyPerson.find_by(person: p, company: employer, company_relation: company_relation)
                if cr.acting != notdismissed
                  cr.update(acting: notdismissed) if update
                  special_logger.info(" - #{p.id} -> #{p.surname} #{p.name} (#{r['id']}) - CompanyPerson updated -> #{employer}: #{r['role']} -> #{notdismissed ? 'acting' : 'non acting'} (id: #{p.id}).")
                  response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{p.surname} #{p.name} (#{r['id']}) - Aggiunto ruolo -> #{employer}: #{r['role']} -> #{notdismissed ? 'attivo' : 'non attivo'} (id: #{p.id}).\n"
                end
              end
              if company_relation == driver
                if p.carwash_driver_code.nil?
                  cwc = CarwashDriverCode.createUnique p if update
                  response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{p.surname} #{p.name} (#{r['id']}) - Aggiunta tessera lavaggio: #{cwc.to_s}.\n"
                  special_logger.info(" - #{p.id} -> #{p.surname} #{p.name} (#{r['id']}) - Carwash code added: #{cwc.to_s}.")
                end
              end
              unless p.has_reference?('Autisti',r['id'])
                mssqlref = MssqlReference.create(local_object: p, remote_object_table: 'Autisti', remote_object_id: r['id'].to_i) if update
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{p.surname} #{p.name} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
                special_logger.info(" - #{p.id} -> #{p.surname} #{p.name} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")
              end

            else
              p.update(name: r['name'], surname: r['surname']) if update
              special_logger.info(" - #{p.id} ->  #{r['cognome']} #{r['nome']} (#{r['id']}) - Created (id: #{p.id}).")
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")}  #{r['cognome']} #{r['nome']} (#{r['id']}) - Creato (id: #{p.id}).\n"
              special_logger.info("name: #{p.surname} #{p.name}.")
              response += "nome: #{p.name}, cognome: #{p.surname}.\n"

              unless p.has_relation?(employer,company_relation)
                CompanyPerson.create(person: p, company: employer, company_relation: company_relation, acting: notdismissed) if update
                special_logger.info(" - #{p.id} -> #{p.surname} #{p.name} (#{r['id']}) - CompanyPerson added -> #{employer}: #{r['role']} -> #{notdismissed ? 'acting' : 'non acting'} (id: #{p.id}).")
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{p.surname} #{p.name} (#{r['id']}) - Aggiunto ruolo -> #{employer}: #{r['role']} -> #{notdismissed ? 'attivo' : 'non attivo'} (id: #{p.id}).\n"
              else
                cr = CompanyPerson.find_by(person: p, company: employer, company_relation: company_relation)
                if cr.acting != notdismissed
                  cr.update(acting: notdismissed) if update
                  special_logger.info(" - #{p.id} -> #{p.surname} #{p.name} (#{r['id']}) - CompanyPerson updated -> #{employer}: #{r['role']} -> #{notdismissed ? 'acting' : 'non acting'} (id: #{p.id}).")
                  response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{p.surname} #{p.name} (#{r['id']}) - Aggiunto ruolo -> #{employer}: #{r['role']} -> #{notdismissed ? 'attivo' : 'non attivo'} (id: #{p.id}).\n"
                end
              end
              if company_relation == driver
                cwc = CarwashDriverCode.createUnique p if update
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{p.surname} #{p.name} (#{r['id']}) - Aggiunta tessera lavaggio: #{cwc.to_s}.\n"
                special_logger.info(" - #{v.id} -> #{p.surname} #{p.name} (#{r['id']}) - Carwash code added: #{cwc.to_s}.")
              end
              unless p.has_reference?('Autisti',r['id'])
                mssqlref = MssqlReference.create(local_object: p, remote_object_table: 'Autisti', remote_object_id: r['id'].to_i) if update
                response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['cognome']} #{r['nome']} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
                special_logger.info(" - #{p.id} -> #{r['cognome']} #{r['nome']} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")
              end
            end
          end
        rescue Exception => e
          special_logger.error("  - #{r['plate']} (#{r['id']}) #{e.message}\n#{e.backtrace}")
          response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} -  -> #{r['plate']} (#{r['id']}) #{e.message}\n#{e.backtrace}</span>\n"

        end
      end
    rescue Exception => e
      special_logger.error("#{e.message}\n#{e.backtrace}")
      response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} - #{e.message}\n#{e.backtrace}</span>\n"

    end

    return {response: response, array: [] }
  end

  def to_s
    "id: #{self.id}, local_object_id: #{self.local_object_id}, local_object_type: #{self.local_object_type}, remote_object_id: #{self.remote_object_id}, remote_object_table: #{self.remote_object_table}"
  end

  private

  def self.special_logger
    @@special_logger ||= Logger.new("#{Rails.root}/log/mssql_reference.log")
  end

  def self.get_client
    TinyTds::Client.new username: ENV['RAILS_MSSQL_USER'], password: ENV['RAILS_MSSQL_PASS'], host: ENV['RAILS_MSSQL_HOST'], port: ENV['RAILS_MSSQL_PORT'], database: ENV['RAILS_MSSQL_DB']
  end
end
