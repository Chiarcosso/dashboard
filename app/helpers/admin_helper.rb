module AdminHelper
  include ErrorHelper
  def get_vehicle_basis

    res = Hash.new
    res[:plate_info] = VehicleInformationType.plate
    res[:chassis_info] = VehicleInformationType.chassis
    res[:atc] = Company.chiarcosso
    res[:te] = Company.transest
    res[:ec] = Company.edilizia
    res[:no_owner] = Company.not_available
    res[:sw] = VehicleTypology.find_by(:name => 'Station wagon')
    res[:no_vehicle_type] = VehicleType.not_available
    res[:no_vehicle_typology] = VehicleTypology.not_available
    res[:motivo_fuori_parco] = VehicleInformationType.find_by(name: 'Motivo fuori parco')
    res[:motivo_fuori_parco] = VehicleInformationType.create(name: 'Motivo fuori parco') if res[:motivo_fuori_parco].nil?
    res[:posti_a_sedere] = VehicleInformationType.find_by(name: 'Posti a sedere')
    res[:posti_a_sedere] = VehicleInformationType.create(name: 'Posti a sedere') if res[:posti_a_sedere].nil?
    res
  end

  def get_vehicle_objects(r,res = get_vehicle_basis,update)

    res[:response] = ''
    res[:vehicle_equipments] = Array.new
    res[:vehicle_type] = VehicleType.find_by(:name => r['type'])
    if res[:vehicle_type].nil?
      @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle type: #{r['type']}"
      res[:response] += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Tipo non valido: #{r['type']}</span>\n"
      mssql_reference_logger.error(@error)
    end
    res[:property] = res[:atc] if r['property'] == 'A'
    res[:property] = res[:te] if r['property'] == 'T'
    res[:property] = res[:ec] if r['property'] == 'E'
    res[:property] = res[:no_owner] if r['property'] == '' || r['property'].nil?
    if res[:property].nil?
      @error = " #{r['plate']} (#{r['id']}) - Invalid property: #{r['property']}"
      res[:response] += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Proprietà non valida: #{r['property']}</span>\n"
      mssql_reference_logger.error(@error)
    end
    res[:manufacturer] = Company.find_by(:name => r['manufacturer'])
    res[:manufacturer] = res[:no_owner] if res[:manufacturer].nil?
    if res[:manufacturer].nil?
      res[:manufacturer] = Company.create(name: r['manufacturer'], vehicle_manufacturer: true) if update
      # @error = " #{r['plate']} (#{r['id']}) - Invalid manufacturer: #{r['manufacturer']}"
      res[:response] += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Produttore creato: #{r['manufacturer']}</span>\n"
      ErrorMailer.error_report("Produttore di veicoli creato: #{r['manufacturer']}","Vehicle update - get vehicle basis")
      # mssql_reference_logger.error(@error)
    end
    res['serie'] = nil
    if r['model'] =~ /\d serie$/
      res['serie'] = r['model'][/(\d) serie$/,1].to_i
      r['model'] = r['model'][/^(.*) \d serie$/,1]
    end

    res[:model] = VehicleModel.where(:name => r['model'], :manufacturer => res[:manufacturer]).first
    if res[:model].nil?
      # @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle model: #{r['manufacturer']} #{r['model']}"
      res[:model] = VehicleModel.create(name: r['model'], manufacturer: res[:manufacturer]) if update
      res[:response] += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Modello creato: #{r['manufacturer']} #{r['model']}</span>\n"
      r['manufacturer']
      # mssql_reference_logger.error(@error)
    end
    res[:registration_model] = r['registration_model']
    if r['notdismissed'] == false
      res[:dismissed] = true
    else
      res[:dismissed] = false
    end
    if r['typology'] == '' or r['typology'] == 'NULL' or r['typology'].nil?
      res[:vehicle_typology] = res[:no_vehicle_typology]
    else
      if r['typology'] == 'Scarrabile con caricatore'
        res[:vehicle_typology] = VehicleTypology.find_by(:name => 'Scarrabile con gancio')
        res[:vehicle_equipments] << VehicleEquipment.find_by(name: 'Caricatore')
      elsif r['typology'] == 'Ribaltabile trilaterale con gr'
        res[:vehicle_typology] = VehicleTypology.find_by(:name => 'Ribaltabile trilaterale')
        res[:vehicle_equipments] << VehicleEquipment.find_by(name: 'Caricatore')
      else
        res[:vehicle_typology] = VehicleTypology.find_by(:name => r['typology'])
      end
      if res[:vehicle_typology].nil?
        # @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle typology: #{r['typology']}"
        # res[:response] += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Tipologia non valida: #{r['typology']}</span>\n"
        # mssql_reference_logger.error(@error)
        res[:vehicle_typology] = VehicleTypology.create(name: r['typology'])
      end
    end
    res[:mileage] = r['mileage'].to_i
    begin
      res[:registration_date] = DateTime.parse(r['registration_date']) unless r['registration_date'].nil?
    rescue
      @error = " #{r['plate']} (#{r['id']}) - Invalid Registration date: #{r['registration_date']}"
      res[:response] += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Data immatricolazione non valida: #{r['registration_date']}</span>\n"
      mssql_reference_logger.error(@error)
    end
    if r['category'] == '' or r['category'] == 'NULL' or r['category'].nil?
      res[:vehicle_category] = VehicleCategory.not_available
    else
      res[:vehicle_category] = VehicleCategory.find_by(:name => r['category'])
      if res[:vehicle_category].nil?
        @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle category: #{r['category']}"
        res[:response] += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Categoria non valida: #{r['category']}</span>\n"
        mssql_reference_logger.error(@error)
      end
    end
    if r['carwash_code'].nil? or r['carawash_code'] == ''
      r['carwash_code'] = res[:carwash_code] = 'N/D'
    else
      r['carwash_code'] = res[:carwash_code] = Vehicle.carwash_codes.key(r['carwash_code'].to_i)
    end
    if r['plate'].nil?
      @error = " #{r['plate']} (#{r['id']}) - Blank plate"
      res[:response] += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Targa mancante</span>\n"
      mssql_reference_logger.error(@error)
    else
      res[:plate] = r['plate']
      res[:vehicle] = Vehicle.find_by_plate(r['plate'].tr('. *-',''))
    end
    unless @error.nil?
      ErrorMailer.error_report(@error,"Vehicles update - get vehicle objects")
    end
    res
  end

  def create_vehicle_from_veicoli(r,update = true,vbase = get_vehicle_basis)
    @error = nil
    data = get_vehicle_objects(r,vbase,update)
    begin
      # v = data[:vehicle] = Vehicle.find_by_plate(r['plate'].tr('. *-',''))
      v = data[:vehicle] = Vehicle.find_by_reference(r['table_name'],r['id'])
      v = data[:vehicle] = Vehicle.find_by_plate(r['plate'].tr('. *-','')) if v.nil?

      if !v.nil? && r['typology'] == r['no_vehicle_typology'] && !v.typology.nil?
        r['typology'] = v.typology
      end

      if @error.nil?
        if v.nil?
          if update

            v = Vehicle.create(vehicle_type: data[:vehicle_type], property: data[:property], model: data[:model], registration_model: data[:registration_model], dismissed: data[:dismissed], vehicle_typology: data[:vehicle_typology], mileage: data[:mileage], registration_date: data[:registration_date], vehicle_category: data[:vehicle_category], carwash_code: data[:carwash_code])
          else
            v = Vehicle.new(vehicle_type: data[:vehicle_type], property: data[:property], model: data[:model], registration_model: data[:registration_model], dismissed: data[:dismissed], vehicle_typology: data[:vehicle_typology], mileage: data[:mileage], registration_date: data[:registration_date], vehicle_category: data[:vehicle_category], carwash_code: data[:carwash_code])
            v.id = 0
          end

          VehicleInformation.create(vehicle: v, vehicle_information_type: data[:plate_info], information: r['plate'].tr('. *-','').upcase, date: data[:registration_date]) if update
          mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Created (id: #{v.id}).")
          data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Creato (id: #{v.id}).\n"
          mssql_reference_logger.info("vehicle_type: #{data[:vehicle_type].name}, property: #{data[:property].name}, model: #{data[:model].complete_name}, registration_model: #{data[:registration_model]}, dismissed: #{data[:dismissed].to_s}, vehicle_typology: #{data[:vehicle_typology].name}, mileage: #{data[:mileage]}, registration_date: #{data[:registration_date].strftime("%d/%m/%Y")}, vehicle_category: #{data[:vehicle_category].name}.")
          data[:response] += "tipo: #{data[:vehicle_type].name}, proprietà: #{data[:property].name}, modello: #{data[:model].complete_name}, modello libretto: #{data[:registration_model]}, dismesso: #{data[:dismissed].to_s}, tipologia: #{data[:vehicle_typology].name}, chilometraggio: #{data[:mileage]}, data immatricolazione: #{data[:registration_date].nil?? '' : data[:registration_date].strftime("%d/%m/%Y")}, categoria: #{data[:vehicle_category].name}.\n"

          VehicleInformation.create(vehicle: v, vehicle_information_type: data[:chassis_info], information: r['chassis'].tr('. *-','').upcase, date: data[:registration_date]) unless r['chassis'].to_s == '' or r['chassis'].nil? or !update
          mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Chassis added -> #{r['chassis']} (id: #{v.id}).")
          data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto telaio -> #{r['chassis']} (id: #{v.id}).\n"

          data[:vehicle_equipments].each do |e|
            v.vehicle_equipments << e if update
          end
          if data[:vehicle_equipments].size > 0
            data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Attrezzatura: #{data[:vehicle_equipments].pluck(:name).join(', ')}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Equipment: #{data[:vehicle_equipments].pluck(:name).join(', ')}.")
          end

          if v.carwash_vehicle_code.nil? and v.carwash_code != 'N/D'
            cwc = CarwashVehicleCode.createUnique v if update
            data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunta tessera lavaggio: #{cwc.to_s}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Carwash code added: #{cwc.to_s}.")
          end
          unless v.has_property?( data[:property])
            if update
              vp = VehicleProperty.create(vehicle: v, owner: data[:property], date_since: v.registration_date)
            else
              vp = VehicleProperty.new(vehicle: v, owner: data[:property], date_since: v.registration_date)
            end
            data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunta proprietà: #{vp.owner.complete_name}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Property added: #{vp.owner.complete_name} #{I18n.l vp.date_since}.")
          end
          mssqlref = MssqlReference.create(local_object: v, remote_object_table: r['table_name'], remote_object_id: r['id'].to_i) if update
          data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
          mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")

        elsif v.check_properties(r)

          data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - A posto (id: #{v.id}).\n"
          if v.carwash_vehicle_code.nil? and v.carwash_code != 'N/D'
            cwc = CarwashVehicleCode.createUnique v if update
            data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunta tessera lavaggio: #{cwc.to_s}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Carwash code added: #{cwc.to_s}.")
          end
          unless v.has_reference?( r['table_name'],r['id'])
            mssqlref = MssqlReference.create(local_object: v, remote_object_table: r['table_name'], remote_object_id: r['id'].to_i) if update
            data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")
          end
          unless v.has_property?( data[:property])
            if update
              vp = VehicleProperty.create(vehicle: v, owner: data[:property], date_since: v.registration_date)
            else
              vp = VehicleProperty.new(vehicle: v, owner: data[:property], date_since: v.registration_date)
            end
            data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunta proprietà: #{vp.owner.complete_name}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Property added: #{vp.owner.complete_name} #{I18n.l vp.date_since}.")
          end
          if v.is_a?(Vehicle) && VehicleInformation.find_by(vehicle: v, information: r['plate'].tr('. *-','').upcase).nil?
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Plate changed #{v.plate} (id: #{v.id}).")
            data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Ritargato #{v.plate} (id: #{v.id}).\n"
            VehicleInformation.create(vehicle: v, vehicle_information_type: data[:plate_info], information: r['plate'].tr('. *-','').upcase, date: Date.today) if update
          end
        else

          mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Updated (id: #{v.id}).")
          data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiornato (id: #{v.id}).\n"

          mssql_reference_logger.info("Dashboard - vehicle_type: #{v.type.nil? ? '' : v.type.is_a?(String)? v.type : v.type.name}, property: #{v.property.nil? ? '' : v.property.name}, model: #{v.model.nil?? '' : v.model.is_a?(String)  ? v.model : v.model.complete_name}, registration_model: #{v.registration_model}, dismissed: #{v.dismissed.to_s}, vehicle_typology: #{v.typology.nil? ? '' : v.typology.is_a?(String)? v.typology : v.typology.name}, mileage: #{v.mileage}, registration_date: #{v.registration_date.nil?? '' : v.registration_date.strftime("%d/%m/%Y")}, vehicle_category: #{v.category.nil? ? '' :v.category.name}, carwash_code: #{v.carwash_code}.")
          data[:response] += "Dashboard - tipo: #{v.type.is_a?(String)? v.type : v.type.name}, proprietà: #{v.property.nil? ? '' : v.property.name}, modello: #{v.model.nil?? '' : v.model.is_a?(String) ? v.model : v.model.complete_name}, modello libretto: #{v.registration_model}, dismesso: #{v.dismissed.to_s}, tipologia: #{v.typology.is_a?(String)? v.typology : v.typology.name}, chilometraggio: #{v.mileage}, data immatricolazione: #{v.registration_date.nil?? '' : v.registration_date.strftime("%d/%m/%Y")}, categoria: #{v.category.name}, codice_lavaggio: #{v.carwash_code}.\n"
          if v.is_a?(Vehicle)
            v.update(vehicle_type: data[:vehicle_type], property: data[:property], model: data[:model], registration_model: data[:registration_model], dismissed: data[:dismissed], vehicle_typology: data[:vehicle_typology], mileage: data[:mileage].to_i > v.mileage.to_i ? data[:mileage].to_i : v.mileage.to_i, registration_date: data[:registration_date], vehicle_category: data[:vehicle_category], carwash_code: data[:carwash_code]) if update
            if v.find_information(data[:chassis_info]).nil?
              VehicleInformation.create(vehicle: v, vehicle_information_type: data[:chassis_info], information: r['chassis'].tr('. *-','').upcase, date: data[:registration_date]) if update
              mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Chassis added -> #{r['chassis']} (id: #{v.id}).")
              data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto telaio -> #{r['chassis']} (id: #{v.id}).\n"
            end
            v.vehicle_equipments.clear if update
            data[:vehicle_equipments].each do |e|
              v.vehicle_equipments << e if update
            end
            if data[:vehicle_equipments].size > 0
              data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Attrezzatura: #{data[:vehicle_equipments].pluck(:name).join(', ')}.\n"
              mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Equipment: #{data[:vehicle_equipments].pluck(:name).join(', ')}.")
            end
            if v.carwash_vehicle_code.nil? and v.carwash_code != 'N/D'
              cwc = CarwashVehicleCode.createUnique v if update
              data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunta tessera lavaggio: #{cwc.to_s}.\n"
              mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Carwash code added: #{cwc.to_s}.")
            end
            unless v.has_property?( data[:property])
              if update
                vp = VehicleProperty.create(vehicle: v, owner: data[:property], date_since: v.registration_date)
              else
                vp = VehicleProperty.new(vehicle: v, owner: data[:property], date_since: v.registration_date)
              end
              data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunta proprietà: #{vp.owner.complete_name}.\n"
              mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Property added: #{vp.owner.complete_name} #{I18n.l vp.date_since}.")
            end
          elsif v.is_a?(ExternalVehicle)
            v.update(vehicle_type: data[:vehicle_type], owner: data[:property], dismissed: data[:dismissed], vehicle_typology: data[:vehicle_typology], mileage: data[:mileage].to_i > v.mileage.to_i ? data[:mileage].to_i : v.mileage.to_i) if update
          end
          data[:response] += "Access - tipo: #{data[:vehicle_type].name}, proprietà: #{data[:property].name}, modello: #{data[:model].complete_name}, modello libretto: #{data[:registration_model]}, dismesso: #{data[:dismissed].to_s}, tipologia: #{data[:vehicle_typology].name}, chilometraggio: #{data[:mileage]}, data immatricolazione: #{data[:registration_date].strftime("%d/%m/%Y")}, categoria: #{data[:vehicle_category].name}, codice_lavaggio: #{data[:carwash_code]}.\n"
          mssql_reference_logger.info("Access - vehicle_type: #{data[:vehicle_type].name}, property: #{data[:property].name}, model: #{data[:model].complete_name}, registration_model: #{data[:registration_model]}, dismissed: #{data[:dismissed].to_s}, vehicle_typology: #{data[:vehicle_typology].name}, mileage: #{data[:mileage]}, registration_date: #{data[:registration_date].strftime("%d/%m/%Y")}, vehicle_category: #{data[:vehicle_category].name}, carwash_code: #{data[:carwash_code]}.")

          if v.is_a?(Vehicle) && VehicleInformation.find_by(vehicle: v, information: r['plate'].tr('. *-','').upcase).nil?
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Plate changed #{v.plate} (id: #{v.id}).")
            data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Ritargato #{v.plate} (id: #{v.id}).\n"
            VehicleInformation.create(vehicle: v, vehicle_information_type: data[:plate_info], information: r['plate'].tr('. *-','').upcase, date: Date.today) if update
          end
          unless v.has_reference?( r['table_name'],r['id'])
            mssqlref = MssqlReference.create(local_object: v, remote_object_table: r['table_name'], remote_object_id: r['id'].to_i) if update
            data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")
          end
        end
      end
    rescue Exception => e

      ErrorMailer.error_report("#{e.message}\n#{e.backtrace.join("\n")}","Vehicle update")
      mssql_reference_logger.error("  - #{r['plate']} (#{r['id']}) #{e.message}\n#{e.backtrace}")
      data[:response] += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} -  -> #{r['plate']} (#{r['id']}) #{e.message}\n#{e.backtrace}</span>\n"

    end
    data[:response]
  end

  def get_external_vehicle_objects(r,res = get_vehicle_basis,update)

    res[:response] = ''
    if r['type'].nil?
      res[:vehicle_type] = res[:no_vehicle_type]
    else
      res[:vehicle_type] = VehicleType.find_by(:name => r['type'])
      if res[:vehicle_type].nil?
        res[:vehicle_type] = VehicleType.create(:name => r['type'])
      end
    end




    if r['typology'] == '' or r['typology'] == 'NULL' or r['typology'].nil?
      res[:vehicle_typology] = res[:no_vehicle_typology]
    else
      res[:vehicle_typology] = VehicleTypology.find_by(:name => r['typology'])
    end

    if res[:vehicle_typology].nil?
      @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle typology: #{r['typology']}"
      res[:response] += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Tipologia non valida: #{r['typology']}</span>\n"
      mssql_reference_logger.error(@error)
    end
    # if r['owner'].nil? and r['idfornitore'].nil?
    #   # @error = " #{r['plate']} (#{r['id']}) - no owner id"
    #   # res[:response] += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Id fornitore mancante</span>\n"
    #   # mssql_reference_logger.error(@error)
    #   r['owner'] = res[:no_owner]
    # else
      if (r['owner'].nil? || r['owner'] == '') and r['idfornitore'].nil?
        res[:owner] = res[:no_owner]
      else
        if r['owner'].nil?
          res[:owner] = Company.find_or_create_by_reference('Clienti',r['idfornitore'].to_i)
        else
          res[:owner] = Company.find_by(:name => r['owner'].titleize)
        end
      end
      if res[:owner].nil?
        if update
          res[:owner] = Company.create(:name => r['owner'].titleize, transporter: true)
        else
          res[:owner] = Company.new(:name => r['owner'].titleize, transporter: true)
        end
        res[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Creata ditta: #{res[:owner].name} (id: #{res[:owner].id})\n"
        mssql_reference_logger.error(@error)
      end
    # end
    res[:idveicolo] = r['id']
    if r['idfornitore'].nil?
      res[:idfornitore] = 0
    else
      res[:idfornitore] = r['idfornitore']
    end
    if r['plate'].nil?
      @error = " #{r['plate']} (#{r['id']}) - Blank plate"
      res[:response] += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Targa mancante</span>\n"
      mssql_reference_logger.error(@error)
    else
      res[:plate] = r['plate']
      res[:vehicle] = ExternalVehicle.find_by(plate: r['plate'].tr('. *-',''))
    end
    res
  end

  def create_external_vehicle_from_veicoli(r,update = true,vbase = get_vehicle_basis)
    @error = nil
    data = get_external_vehicle_objects(r,vbase,update)
    begin
      # v = data[:vehicle]
      v = data[:vehicle] = Vehicle.find_by_reference(r['table_name'],r['id'])
      v = data[:vehicle] = Vehicle.find_by_plate(r['plate'].tr('. *-','')) if v.nil?

      if !v.nil? && r['typology'] == r['no_vehicle_typology'] && !v.typology.nil?
        r['typology'] = v.typology
      end

      if @error.nil?
        if v.nil?
          if update
            v = ExternalVehicle.create(plate: data[:plate].tr('. *-','').upcase, vehicle_type: data[:vehicle_type], owner: data[:owner], vehicle_typology: data[:vehicle_typology], id_veicolo: data[:idveicolo], id_fornitore: data[:idfornitore])
          else
            v = ExternalVehicle.new
            v.id = 0
          end

          mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Created (id: #{v.id}).")
          data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Creato (id: #{v.id}).\n"
          mssql_reference_logger.info("vehicle_type: #{data[:vehicle_type].name}, owner: #{data[:owner].name}, vehicle_typology: #{data[:vehicle_typology].name}.")
          data[:response] += "tipo: #{data[:vehicle_type].name}, proprietà: #{data[:owner].name}, tipologia: #{data[:vehicle_typology].name}.\n"

          mssqlref = MssqlReference.create(local_object: v, remote_object_table: r['table_name'], remote_object_id: r['id'].to_i) if update
          data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
          mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")

        elsif v.check_properties(data)

          data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - A posto (id: #{v.id}).\n"

          unless v.has_reference?( r['table_name'],r['id'])
            mssqlref = MssqlReference.create(local_object: v, remote_object_table: r['table_name'], remote_object_id: r['id'].to_i) if update
            data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")
          end
        else

          mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Updated (id: #{v.id}).")
          data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiornato (id: #{v.id}).\n"
          mssql_reference_logger.info("Dashboard - vehicle_type: #{v.type.nil?? '' : v.type.is_a?(String)? v.type : v.type.name}, owner: #{v.owner.nil?? '' : v.owner.name}, vehicle_typology: #{v.typology.nil?? '' : v.typology.is_a?(String)? v.typology :  v.typology.name}, id_veicolo: #{v.id_veicolo}, id_fornitore: #{v.id_fornitore}.")
          data[:response] += "Dashboard - tipo: #{v.type.nil?? '' : v.type.is_a?(String)? v.type :  v.type.name}, proprietà: #{v.owner.nil?? '' : v.owner.name}, tipologia: #{v.typology.nil?? '' : v.typology.is_a?(String)? v.typology :  v.typology.name}, id_veicolo: #{v.id_veicolo}, id_fornitore: #{v.id_fornitore}.\n"
          v.update(vehicle_type: data[:vehicle_type], owner: data[:owner], vehicle_typology: data[:vehicle_typology], id_veicolo: data[:idveicolo], id_fornitore: data[:idfornitore]) if update
          data[:response] += "Access - tipo: #{data[:vehicle_type].name}, proprietà: #{data[:owner].name}, tipologia: #{data[:vehicle_typology].name}, id_veicolo: #{data[:idveicolo]}, id_fornitore: #{data[:idfornitore]}.\n"
          mssql_reference_logger.info("Access - vehicle_type: #{data[:vehicle_type].name}, owner: #{data[:owner].name}, vehicle_typology: #{data[:vehicle_typology].name}, id_veicolo: #{data[:idveicolo]}, id_fornitore: #{data[:idfornitore]}.")

          unless v.has_reference?( r['table_name'],r['id'])
            mssqlref = MssqlReference.create(local_object: v, remote_object_table: r['table_name'], remote_object_id: r['id'].to_i) if update
            data[:response] += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")
          end
        end
      end
    rescue Exception => e
      ErrorMailer.error_report("#{e.message}\n#{e.backtrace.join("\n")}","External Vehicle update")
      mssql_reference_logger.error("  - #{r['plate']} (#{r['id']}) #{e.message}\n#{e.backtrace}")
      data[:response] += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} -  -> #{r['plate']} (#{r['id']}) #{e.message}\n#{e.backtrace}</span>\n"

    end
    data[:response]
  end

  def create_vehicle_from_rimorchi1(r,update,vbase)
    @error = nil
    data = get_vehicle_objects(r,vbase)
    # vehicle_equipments = Array.new
    # vehicle_type = VehicleType.find_by(:name => r['type'])
    # if vehicle_type.nil?
    #   @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle type: #{r['type']}"
    #   response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Tipo non valido: #{r['type']}</span>\n"
    #   mssql_reference_logger.error(@error)
    # end
    # property = atc if r['property'] == 'A'
    # property = te if r['property'] == 'T'
    # if property.nil?
    #   @error = " #{r['plate']} (#{r['id']}) - Invalid property: #{r['property']}"
    #   response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Proprietà non valida: #{r['property']}</span>\n"
    #   mssql_reference_logger.error(@error)
    # end
    # manufacturer = Company.find_by(:name => r['manufacturer'])
    # if manufacturer.nil?
    #   @error = " #{r['plate']} (#{r['id']}) - Invalid manufacturer: #{r['manufacturer']}"
    #   response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Produttore non valido: #{r['manufacturer']}</span>\n"
    #   mssql_reference_logger.error(@error)
    # end
    # model = VehicleModel.where(:name => r['model'], :manufacturer => manufacturer).first
    # if model.nil?
    #   @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle model: #{r['manufacturer']} #{r['model']}"
    #   response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Modello non valido: #{r['manufacturer']} #{r['model']}</span>\n"
    #   mssql_reference_logger.error(@error)
    # end
    # registration_model = r['registration_model']
    # if r['notdismissed'] == false
    #   dismissed = true
    # else
    #   dismissed = false
    # end
    # if r['typology'] == '' or r['typology'] == 'NULL' or r['typology'].nil?
    #   vehicle_typology = VehicleTypology.not_available
    # else
    #   if r['typology'] == 'Scarrabile con caricatore'
    #     vehicle_typology = VehicleTypology.find_by(:name => 'Scarrabile con gancio')
    #     vehicle_equipments << VehicleEquipment.find_by(name: 'Caricatore')
    #   else
    #     vehicle_typology = VehicleTypology.find_by(:name => r['typology'])
    #   end
    #   if vehicle_typology.nil?
    #     @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle typology: #{r['typology']}"
    #     response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Tipologia non valida: #{r['typology']}</span>\n"
    #     mssql_reference_logger.error(@error)
    #   end
    # end
    # mileage = r['mileage'].to_i
    # begin
    #   registration_date = DateTime.parse(r['registration_date']) unless r['registration_date'].nil?
    # rescue
    #   @error = " #{r['plate']} (#{r['id']}) - Invalid Registration date: #{r['registration_date']}"
    #   response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Data immatricolazione non valida: #{r['registration_date']}</span>\n"
    #   mssql_reference_logger.error(@error)
    # end
    # if r['category'] == '' or r['category'] == 'NULL' or r['category'].nil?
    #   vehicle_category = VehicleCategory.not_available
    # else
    #   vehicle_category = VehicleCategory.find_by(:name => r['category'])
    #   if vehicle_category.nil?
    #     @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle category: #{r['category']}"
    #     response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Categoria non valida: #{r['category']}</span>\n"
    #     mssql_reference_logger.error(@error)
    #   end
    # end
    # if r['carwash_code'].nil? or r['carawash_code'] == ''
    #   r['carwash_code'] = carwash_code = 'N/D'
    # else
    #   r['carwash_code'] = carwash_code = Vehicle.carwash_codes.key(r['carwash_code'].to_i)
    # end
    # if r['plate'].nil?
    #   @error = " #{r['plate']} (#{r['id']}) - Blank plate"
    #   response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Targa mancante</span>\n"
    #   mssql_reference_logger.error(@error)
    # else
    #   v = Vehicle.find_by_plate(r['plate'].tr('. *-',''))
    # end
    begin
      if @error.nil?
        # v = data[:vehicle]
        v = data[:vehicle] = Vehicle.find_by_reference(r['table_name'],r['id'])
        v = data[:vehicle] = Vehicle.find_by_plate(r['plate'].tr('. *-','')) if v.nil?

        if !v.nil? && r['typology'] == r['no_vehicle_typology'] && !v.typology.nil?
          r['typology'] = v.typology
        end

        if v.nil?
          if update
            v = Vehicle.create(vehicle_type: data[:vehicle_type], property: data[:property], model: data[:model], registration_model: data[:registration_model], dismissed: data[:dismissed], vehicle_typology: data[:vehicle_typology], mileage: data[:mileage], registration_date: data[:registration_date], vehicle_category: data[:vehicle_category], carwash_code: data[:carwash_code])
          else
            v = Vehicle.new
            v.id = 0
          end

          mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Created (id: #{v.id}).")
          response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Creato (id: #{v.id}).\n"
          mssql_reference_logger.info("vehicle_type: #{vehicle_type.name}, property: #{property.name}, model: #{model.complete_name}, registration_model: #{registration_model}, dismissed: #{dismissed.to_s}, vehicle_typology: #{vehicle_typology.name}, mileage: #{mileage}, registration_date: #{registration_date.strftime("%d/%m/%Y")}, vehicle_category: #{vehicle_category.name}.")
          response += "tipo: #{vehicle_type.name}, proprietà: #{property.name}, modello: #{model.complete_name}, modello libretto: #{registration_model}, dismesso: #{dismissed.to_s}, tipologia: #{vehicle_typology.name}, chilometraggio: #{mileage}, data immatricolazione: #{registration_date.strftime("%d/%m/%Y")}, categoria: #{vehicle_category.name}.\n"

          VehicleInformation.create(vehicle: v, vehicle_information_type: plate, information: r['plate'].tr('. *-','').upcase, date: registration_date) if update

          VehicleInformation.create(vehicle: v, vehicle_information_type: chassis, information: r['chassis'].tr('. *-','').upcase, date: registration_date) unless r['chassis'].to_s == '' if update
          mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Chassis added -> #{r['chassis']} (id: #{v.id}).")
          response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto telaio -> #{r['chassis']} (id: #{v.id}).\n"

          vehicle_equipments.each do |e|
            v.vehicle_equipments << e if update
          end
          if vehicle_equipments.size > 0
            response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Attrezzatura: #{vehicle_equipments.pluck(:name).join(', ')}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Equipment: #{vehicle_equipments.pluck(:name).join(', ')}.")
          end
          if v.find_information(motivo_fuori_parco).nil?
            unless r['motivo_fuori_parco'].nil? or r['motivo_fuori_parco'] == ''
              VehicleInformation.create(vehicle: v, vehicle_information_type: motivo_fuori_parco, information: r['motivo_fuori_parco'], date: registration_date) unless r['posti_a_sedere'].to_s == '' if update
              mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Dismission cause added -> #{r['motivo_fuori_parco']} (id: #{v.id}).")
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto motivo fuori parco -> #{r['motivo_fuori_parco']} (id: #{v.id}).\n"
            end
          end
          if v.carwash_vehicle_code.nil? and v.carwash_code == 'N/D'
            cwc = CarwashVehicleCode.createUnique v if update
            response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunta tessera lavaggio: #{cwc.to_s}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Carwash code added: #{cwc.to_s}.")
          end
          mssqlref = MssqlReference.create(local_object: v, remote_object_table: r['table_name'], remote_object_id: r['id'].to_i) if update
          response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
          mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")

        elsif v.check_properties(r)

          response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - A posto (id: #{v.id}).\n"
          if v.find_information(motivo_fuori_parco).nil?
            unless r['motivo_fuori_parco'].nil? or r['motivo_fuori_parco'] == ''
              VehicleInformation.create(vehicle: v, vehicle_information_type: motivo_fuori_parco, information: r['motivo_fuori_parco'], date: registration_date) unless r['posti_a_sedere'].to_s == '' if update
              mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Dismission cause added -> #{r['motivo_fuori_parco']} (id: #{v.id}).")
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto motivo fuori parco -> #{r['motivo_fuori_parco']} (id: #{v.id}).\n"
            end
          end
          if v.carwash_vehicle_code.nil? and v.carwash_code == 'N/D'
            cwc = CarwashVehicleCode.createUnique v if update
            response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunta tessera lavaggio: #{cwc.to_s}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Carwash code added: #{cwc.to_s}.")
          end
          unless v.has_reference?( r['table_name'],r['id'])
            mssqlref = MssqlReference.create(local_object: v, remote_object_table: r['table_name'], remote_object_id: r['id'].to_i) if update
            response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")
          end
        else

          mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Updated (id: #{v.id}).")
          response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiornato (id: #{v.id}).\n"
          mssql_reference_logger.info("Dashboard - vehicle_type: #{v.type.name}, property: #{v.property.name}, model: #{v.model.nil?? '' :  v.model.is_a?(String) ? v.model : v.model.complete_name}, registration_model: #{v.registration_model}, dismissed: #{v.dismissed.to_s}, vehicle_typology: #{v.typology.name}, mileage: #{v.mileage}, registration_date: #{v.registration_date.nil?? '' : v.registration_date.strftime("%d/%m/%Y")}, vehicle_category: #{v.category.name}, carwash_code: #{v.carwash_code}.")
          response += "Dashboard - tipo: #{v.type.name}, proprietà: #{v.property.name}, modello: #{v.model.nil?? '' :  v.model.is_a?(String) ? v.model : v.model.complete_name}, modello libretto: #{v.registration_model}, dismesso: #{v.dismissed.to_s}, tipologia: #{v.typology.name}, chilometraggio: #{v.mileage}, data immatricolazione: #{v.registration_date.nil?? '' : v.registration_date.strftime("%d/%m/%Y")}, categoria: #{v.category.name}, codice_lavaggio: #{v.carwash_code}.\n"
          v.update(vehicle_type: vehicle_type, property: property, model: model, registration_model: r['registration_model'], dismissed: dismissed, vehicle_typology: vehicle_typology, mileage: mileage.to_i > v.mileage.to_i ? mileage.to_i : v.mileage.to_i, registration_date: registration_date, vehicle_category: vehicle_category, carwash_code: carwash_code) if update
          mssql_reference_logger.info("Access - vehicle_type: #{vehicle_type.name}, property: #{property.name}, model: #{model.complete_name}, registration_model: #{registration_model}, dismissed: #{dismissed.to_s}, vehicle_typology: #{vehicle_typology.name}, mileage: #{mileage}, registration_date: #{registration_date.strftime("%d/%m/%Y")}, vehicle_category: #{vehicle_category.name}, carwash_code: #{carwash_code}.")
          response += "Access - tipo: #{vehicle_type.name}, proprietà: #{property.name}, modello: #{model.complete_name}, modello libretto: #{registration_model}, dismesso: #{dismissed.to_s}, tipologia: #{vehicle_typology.name}, chilometraggio: #{mileage}, data immatricolazione: #{registration_date.strftime("%d/%m/%Y")}, categoria: #{vehicle_category.name}, codice_lavaggio: #{carwash_code}.\n"

          if v.find_information(data[:chassis_info]).nil?
            VehicleInformation.create(vehicle: v, vehicle_information_type: chassis, information: r['chassis'].tr('. *-','').upcase, date: registration_date) if update
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Chassis added -> #{r['chassis']} (id: #{v.id}).")
            response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto telaio -> #{r['chassis']} (id: #{v.id}).\n"
          end
          v.vehicle_equipments.clear if update
          vehicle_equipments.each do |e|
            v.vehicle_equipments << e if update
          end
          if vehicle_equipments.size > 0
            response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Attrezzatura: #{vehicle_equipments.pluck(:name).join(', ')}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Equipment: #{vehicle_equipments.pluck(:name).join(', ')}.")
          end
          if v.find_information(motivo_fuori_parco).nil?
            unless r['motivo_fuori_parco'].nil? or r['motivo_fuori_parco'] == ''
              VehicleInformation.create(vehicle: v, vehicle_information_type: motivo_fuori_parco, information: r['motivo_fuori_parco'], date: registration_date) unless r['posti_a_sedere'].to_s == '' if update
              mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Dismission cause added -> #{r['motivo_fuori_parco']} (id: #{v.id}).")
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto motivo fuori parco -> #{r['motivo_fuori_parco']} (id: #{v.id}).\n"
            end
          end
          if v.carwash_vehicle_code.nil? and v.carwash_code == 'N/D'
            cwc = CarwashVehicleCode.createUnique v if update
            response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunta tessera lavaggio: #{cwc.to_s}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Carwash code added: #{cwc.to_s}.")
          end
          unless v.has_reference?( r['table_name'],r['id'])
            mssqlref = MssqlReference.create(local_object: v, remote_object_table: r['table_name'], remote_object_id: r['id'].to_i) if update
            response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")
          end
        end
      end
    rescue Exception => e
      ErrorMailer.error_report("#{r['plate']} (#{r['id']})\n\n#{e.message}\n#{e.backtrace.join("\n")}","Vehicle trailer update")
      mssql_reference_logger.error("  - #{r['plate']} (#{r['id']}) #{e.message}\n#{e.backtrace}")
      response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} -  -> #{r['plate']} (#{r['id']}) #{e.message}\n#{e.backtrace}\n</span>"

    end
  end

  def create_vehicle_from_altri_mezzi(r,update)
    @error = nil
    vehicle_equipments = Array.new
    vehicle_type = VehicleType.find_by(:name => r['type'])
    if vehicle_type.nil?
      @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle type: #{r['type']}"
      response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Tipo non valido: #{r['type']}</span>\n"
      mssql_reference_logger.error(@error)
    end
    property = atc if r['property'] == 'A'
    property = te if r['property'] == 'T'
    property = ec if r['property'] == 'E'
    if property.nil?
      @error = " #{r['plate']} (#{r['id']}) - Invalid property: #{r['property']}"
      response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Proprietà non valida: #{r['property']}</span>\n"
      mssql_reference_logger.error(@error)
    end
    manufacturer = Company.find_by(:name => r['manufacturer'])
    if manufacturer.nil?
      @error = " #{r['plate']} (#{r['id']}) - Invalid manufacturer: #{r['manufacturer']}"
      response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Produttore non valido: #{r['manufacturer']}</span>\n"
      mssql_reference_logger.error(@error)
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
      mssql_reference_logger.error(@error)
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
        mssql_reference_logger.error(@error)
      end
    end
    mileage = r['mileage'].to_i
    begin
      registration_date = DateTime.parse(r['registration_date']) unless r['registration_date'].nil?
    rescue
      @error = " #{r['plate']} (#{r['id']}) - Invalid Registration date: #{r['registration_date']}"
      response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Data immatricolazione non valida: #{r['registration_date']}</span>\n"
      mssql_reference_logger.error(@error)
    end
    if r['category'] == '' or r['category'] == 'NULL' or r['category'].nil?
      vehicle_category = VehicleCategory.not_available
    else
      vehicle_category = VehicleCategory.find_by(:name => r['category'])
      if vehicle_category.nil?
        @error = " #{r['plate']} (#{r['id']}) - Invalid vehicle category: #{r['category']}"
        response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Categoria non valida: #{r['category']}</span>\n"
        mssql_reference_logger.error(@error)
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
      mssql_reference_logger.error(@error)
    else

      v = Vehicle.find_by_reference(r['table_name'],r['id'])
      v = Vehicle.find_by_plate(r['plate'].tr('. *-','')) if v.nil?

      if !v.nil? && r['typology'] == r['no_vehicle_typology'] && !v.typology.nil?
        r['typology'] = v.typology
      end
      if v.is_a?(Vehicle) && VehicleInformation.find_by(vehicle: v, information: r['plate'].tr('. *-','').upcase).nil?
        mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Plate changed #{v.plate} (id: #{v.id}).")
        response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Ritargato #{v.plate} (id: #{v.id}).\n"
        VehicleInformation.create(vehicle: v, vehicle_information_type: data[:plate_info], information: r['plate'].tr('. *-','').upcase, date: Date.today) if update
      end
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

          mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Created (id: #{v.id}).")
          response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Creato (id: #{v.id}).\n"
          mssql_reference_logger.info("vehicle_type: #{vehicle_type.name}, property: #{property.name}, model: #{model.complete_name}, registration_model: #{registration_model}, serie: #{serie}, dismissed: #{dismissed.to_s}, vehicle_typology: #{vehicle_typology.name}, mileage: #{mileage}, registration_date: #{registration_date.strftime("%d/%m/%Y")}, vehicle_category: #{vehicle_category.name}.")
          response += "tipo: #{vehicle_type.name}, proprietà: #{property.name}, modello: #{model.complete_name}, modello libretto: #{registration_model}, serie: #{serie}, dismesso: #{dismissed.to_s}, tipologia: #{vehicle_typology.name}, chilometraggio: #{mileage}, data immatricolazione: #{registration_date.strftime("%d/%m/%Y")}, categoria: #{vehicle_category.name}.\n"

          VehicleInformation.create(vehicle: v, vehicle_information_type: plate, information: r['plate'].tr('. *-','').upcase, date: registration_date) if update


          unless r['chassis'].nil? or r['chassis'] == ''
            VehicleInformation.create(vehicle: v, vehicle_information_type: chassis, information: r['chassis'].tr('. *-','').upcase, date: registration_date) unless r['chassis'].to_s == '' if update
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Chassis added -> #{r['chassis']} (id: #{v.id}).")
            response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto telaio -> #{r['chassis']} (id: #{v.id}).\n"
          end
          unless r['posti_a_sedere'].nil? or r['posti_a_sedere'] == ''
            VehicleInformation.create(vehicle: v, vehicle_information_type: posti_a_sedere, information: r['posti_a_sedere'], date: registration_date) unless r['posti_a_sedere'].to_s == '' if update
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Seat number added -> #{r['posti_a_sedere']} (id: #{v.id}).")
            response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto nr. posti a sedere -> #{r['posti_a_sedere']} (id: #{v.id}).\n"
          end
          unless r['motivo_fuori_parco'].nil? or r['motivo_fuori_parco'] == ''
            VehicleInformation.create(vehicle: v, vehicle_information_type: motivo_fuori_parco, information: r['motivo_fuori_parco'], date: registration_date) unless r['posti_a_sedere'].to_s == '' if update
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Dismission cause added -> #{r['motivo_fuori_parco']} (id: #{v.id}).")
            response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto motivo fuori parco -> #{r['motivo_fuori_parco']} (id: #{v.id}).\n"
          end



          vehicle_equipments.each do |e|
            v.vehicle_equipments << e if update
          end
          if vehicle_equipments.size > 0
            response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Attrezzatura: #{vehicle_equipments.pluck(:name).join(', ')}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Equipment: #{vehicle_equipments.pluck(:name).join(', ')}.")
          end

          if v.carwash_vehicle_code.nil? and v.carwash_code == 'N/D'
            cwc = CarwashVehicleCode.createUnique v if update
            response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunta tessera lavaggio: #{cwc.to_s}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Carwash code added: #{cwc.to_s}.")
          end

          mssqlref = MssqlReference.create(local_object: v, remote_object_table: r['table_name'], remote_object_id: r['id'].to_i) if update
          response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
          mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")

        elsif v.check_properties(r)  #Vehicle exists and has the same properties as the importing one

          if v.carwash_vehicle_code.nil? and v.carwash_code == 'N/D'
            cwc = CarwashVehicleCode.createUnique v if update
            response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunta tessera lavaggio: #{cwc.to_s}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Carwash code added: #{cwc.to_s}.")
          end
          response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - A posto (id: #{v.id}).\n"
          unless v.has_reference?( r['table_name'],r['id'])
            mssqlref = MssqlReference.create(local_object: v, remote_object_table: r['table_name'], remote_object_id: r['id'].to_i) if update
            response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")
          end
          if v.find_information(posti_a_sedere).nil?
            unless r['posti_a_sedere'].nil? or r['posti_a_sedere'] == ''
              VehicleInformation.create(vehicle: v, vehicle_information_type: posti_a_sedere, information: r['posti_a_sedere'], date: registration_date) unless r['posti_a_sedere'].to_s == '' if update
              mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Seat number added -> #{r['posti_a_sedere']} (id: #{v.id}).")
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto nr. posti a sedere -> #{r['posti_a_sedere']} (id: #{v.id}).\n"
            end
          end
          if v.find_information(motivo_fuori_parco).nil?
            unless r['motivo_fuori_parco'].nil? or r['motivo_fuori_parco'] == ''
              VehicleInformation.create(vehicle: v, vehicle_information_type: motivo_fuori_parco, information: r['motivo_fuori_parco'], date: registration_date) unless r['posti_a_sedere'].to_s == '' if update
              mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Dismission cause added -> #{r['motivo_fuori_parco']} (id: #{v.id}).")
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto motivo fuori parco -> #{r['motivo_fuori_parco']} (id: #{v.id}).\n"
            end
          end

        else #Vehicle exists but has not the same properties as the importing one


          mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Updated (id: #{v.id}).")
          response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiornato (id: #{v.id}).\n"
          mssql_reference_logger.info("Dashboard - vehicle_type: #{v.type.name}, property: #{v.property.name}, model: #{v.model.nil?? '' :  v.model.is_a?(String) ? v.model : v.model.complete_name}, registration_model: #{v.registration_model}, serie: #{serie}, dismissed: #{v.dismissed.to_s}, vehicle_typology: #{v.typology.name}, mileage: #{v.mileage}, registration_date: #{v.registration_date.nil?? '' : v.registration_date.strftime("%d/%m/%Y")}, vehicle_category: #{v.category.name}, carwash_code: #{v.carwash_code}.")
          response += "Dashboard - tipo: #{v.type.name}, proprietà: #{v.property.name}, modello: #{v.model.nil?? '' :  v.model.is_a?(String) ? v.model : v.model.complete_name}, modello libretto: #{v.registration_model}, serie: #{serie}, dismesso: #{v.dismissed.to_s}, tipologia: #{v.typology.name}, chilometraggio: #{v.mileage}, data immatricolazione: #{v.registration_date.nil?? '' : v.registration_date.strftime("%d/%m/%Y")}, categoria: #{v.category.name}, codice_lavaggio: #{v.carwash_code}.\n"
          v.update(vehicle_type: vehicle_type, property: property, model: model, registration_model: r['registration_model'], serie: serie, dismissed: dismissed, vehicle_typology: vehicle_typology, mileage: mileage.to_i > v.mileage.to_i ? mileage.to_i : v.mileage.to_i, registration_date: registration_date, vehicle_category: vehicle_category, carwash_code: carwash_code) if update
          mssql_reference_logger.info("Access - vehicle_type: #{vehicle_type.name}, property: #{property.name}, model: #{model.complete_name}, registration_model: #{registration_model}, serie: #{serie}, dismissed: #{dismissed.to_s}, vehicle_typology: #{vehicle_typology.name}, mileage: #{mileage}, registration_date: #{registration_date.strftime("%d/%m/%Y")}, vehicle_category: #{vehicle_category.name}, carwash_code: #{carwash_code}.")
          response += "Access - tipo: #{vehicle_type.name}, proprietà: #{property.name}, modello: #{model.complete_name}, modello libretto: #{registration_model}, serie: #{serie}, dismesso: #{dismissed.to_s}, tipologia: #{vehicle_typology.name}, chilometraggio: #{mileage}, data immatricolazione: #{registration_date.strftime("%d/%m/%Y")}, categoria: #{vehicle_category.name}, codice_lavaggio: #{carwash_code}.\n"

          if v.find_information(data[:chassis_info]).nil?
            VehicleInformation.create(vehicle: v, vehicle_information_type: chassis, information: r['chassis'].tr('. *-','').upcase, date: registration_date) if update
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Chassis added -> #{r['chassis']} (id: #{v.id}).")
            response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto telaio -> #{r['chassis']} (id: #{v.id}).\n"
          end
          v.vehicle_equipments.clear if update
          vehicle_equipments.each do |e|
            v.vehicle_equipments << e if update
          end
          if vehicle_equipments.size > 0
            response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Attrezzatura: #{vehicle_equipments.pluck(:name).join(', ')}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Equipment: #{vehicle_equipments.pluck(:name).join(', ')}.")
          end
          if v.find_information(posti_a_sedere).nil?
            unless r['posti_a_sedere'].nil? or r['posti_a_sedere'] == ''
              VehicleInformation.create(vehicle: v, vehicle_information_type: posti_a_sedere, information: r['posti_a_sedere'], date: registration_date) unless r['posti_a_sedere'].to_s == '' if update
              mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Seat number added -> #{r['posti_a_sedere']} (id: #{v.id}).")
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto nr. posti a sedere -> #{r['posti_a_sedere']} (id: #{v.id}).\n"
            end
          end
          if v.find_information(motivo_fuori_parco).nil?
            unless r['motivo_fuori_parco'].nil? or r['motivo_fuori_parco'] == ''
              VehicleInformation.create(vehicle: v, vehicle_information_type: motivo_fuori_parco, information: r['motivo_fuori_parco'], date: registration_date) unless r['posti_a_sedere'].to_s == '' if update
              mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Dismission cause added -> #{r['motivo_fuori_parco']} (id: #{v.id}).")
              response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto motivo fuori parco -> #{r['motivo_fuori_parco']} (id: #{v.id}).\n"
            end
          end
          if v.carwash_vehicle_code.nil? and v.carwash_code == 'N/D'
            cwc = CarwashVehicleCode.createUnique v if update
            response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunta tessera lavaggio: #{cwc.to_s}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - Carwash code added: #{cwc.to_s}.")
          end
          unless v.has_reference?( r['table_name'],r['id'])
            mssqlref = MssqlReference.create(local_object: v, remote_object_table: r['table_name'], remote_object_id: r['id'].to_i) if update
            response += "#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} #{r['plate']} (#{r['id']}) - Aggiunto riferimento MSSQL: #{mssqlref.to_s}.\n"
            mssql_reference_logger.info(" - #{v.id} -> #{r['plate']} (#{r['id']}) - MSSQL reference added: #{mssqlref.to_s}.")
          end
        end
      end
    rescue Exception => e
      ErrorMailer.error_report("#{r['plate']} (#{r['id']})\n\n#{e.message}\n#{e.backtrace.join("\n")}","Other vehicles update")
      mssql_reference_logger.error("  - #{r['plate']} (#{r['id']}) #{e.message}\n#{e.backtrace}")
      response += "<span class=\"error-line\">#{DateTime.current.strftime("%d/%m/%Y %H:%M:%S")} -  -> #{r['plate']} (#{r['id']}) #{e.message}\n#{e.backtrace}</span>\n"

    end
  end

  def query_vehicles
    # client = TinyTds::Client.new username: ENV['RAILS_SQL_USER'], password: ENV['RAILS_SQL_PASS'], host: ENV['RAILS_SQL_HOST'], port: ENV['RAILS_SQL_PORT'], database: ENV['RAILS_SQL_DB']
    @altri_mezzi = MssqlReference::upsync_other_vehicles[:array]
    @veicoli = MssqlReference::upsync_vehicles[:array]
    @rimorchi1 = MssqlReference::upsync_trailers[:array]
    @delete_vehicles = Vehicle.free_to_delete - @veicoli - @altri_mezzi - @rimorchi1
    @no_delete_vehicles = Vehicle.not_free_to_delete - @veicoli - @altri_mezzi - @rimorchi1

    # client.execute("select 'Veicoli' as tabella, idveicolo, targa, ditta, marca, modello from veicoli "\
    #             "where marca is not null and marca != '' and modello is not null and modello != '' "\
    #             "order by targa").each do |r|
    #               v = Vehicle.find_by_plate(r['targa'].tr('. *-',''))
    #               if v.nil?
    #                 @veicoli << {vehicle: v, data: r, color: '#f99', route: :new}
    #               elsif v.check_properties(r)
    #                 @veicoli << {vehicle: v, data: r, color: '#fff', route: nil}
    #               else
    #                 @veicoli << {vehicle: v, data: r, color: '#99f', route: :edit}
    #               end
    #               @delete_vehicles -= [v] unless v.nil?
    #               @no_delete_vehicles -= [v] unless v.nil?
    #             end
    # @veicoli = @veicoli.select { |r| r[:color] == '#f99' } + @veicoli.select { |r| r[:color] == '#99f' } + @veicoli.select { |r| r[:color] == '#fff' }

    # client.execute("select 'Rimorchi1' as tabella, idrimorchio as idveicolo, targa, ditta, marca, "\
    #             "(case tipo when 'S' then 'Semirimorchio' when 'R' then 'Rimorchio' end) as modello "\
    #             "from rimorchi1 "\
    #             "where marca is not null and marca != '' "\
    #             "order by targa").each do |r|
    #               v = Vehicle.find_by_plate(r['targa'].tr('. *-',''))
    #               if v.nil?
    #                 @rimorchi1 << {vehicle: v, data: r, color: '#f99', route: :new}
    #               elsif v.check_properties(r)
    #                 @rimorchi1 << {vehicle: v, data: r, color: '#fff', route: nil}
    #               else
    #                 @rimorchi1 << {vehicle: v, data: r, color: '#99f', route: :edit}
    #               end
    #               @delete_vehicles -= [v] unless v.nil?
    #               @no_delete_vehicles -= [v] unless v.nil?
    #             end
    # # @rimorchi1 = @rimorchi1.select { |r| r[:color] == '#f99' } + @rimorchi1.select { |r| r[:color] == '#99f' } + @rimorchi1.select { |r| r[:color] == '#fff' }
    #
    # client.execute("select 'Altri mezzi' as tabella, convert(int,cod) as idveicolo, targa, ditta, marca, modello "\
    #             "from [Altri mezzi] "\
    #             "where marca is not null and marca != '' and modello is not null and modello != '' "\
    #             "order by targa").each do |r|
    #               v = Vehicle.find_by_plate(r['targa'].tr('. *-',''))
    #               if v.nil?
    #                 @altri_mezzi << {vehicle: v, data: r, color: '#f99', route: :new}
    #               elsif v.check_properties(r)
    #                 @altri_mezzi << {vehicle: v, data: r, color: '#fff', route: nil}
    #               else
    #                 @altri_mezzi << {vehicle: v, data: r, color: '#99f', route: :edit}
    #               end
    #               @delete_vehicles -= [v] unless v.nil?
    #               @no_delete_vehicles -= [v] unless v.nil?
    #             end
    # # @altri_mezzi = @altri_mezzi.select { |r| r[:color] == '#f99' } + @altri_mezzi.select { |r| r[:color] == '#99f' } + @altri_mezzi.select { |r| r[:color] == '#fff' }
    #
    # @delete_vehicles.sort_by! {|v| v.plate}
    # @no_delete_vehicles.sort_by! {|v| v.plate}
    # @plate = VehicleInformationType.plate
    # @chassis = VehicleInformationType.chassis
    # @chiarcosso = Company.chiarcosso
    # @transest = Company.transest
    # @equipment = VehicleEquipment.order(:name).to_a
    # @information_types = VehicleInformationType.order(:name).to_a
    # @transporters = Company.where(transporter: true).order(:name).to_a
    # @manufacturers = Company.where(vehicle_manufacturer: true).order(:name).to_a
  end

  def mssql_reference_logger
    @@mssql_reference_logger ||= Logger.new("#{Rails.root}/log/mssql_reference.log")
  end
end
