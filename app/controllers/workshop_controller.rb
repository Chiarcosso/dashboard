class WorkshopController < ApplicationController

  before_action :get_worksheet, except: [:get_sheet,:create_worksheet,:index,:open_notification]
  before_action :get_check_session, except: [:index]
  before_action :get_workshop_operation, only: [:start_operation, :pause_operation, :finish_operation,  :delete_operation]
  before_action :set_protocol, except: [:index]
  before_action :set_station

  def get_sheet
    respond_to do |format|
      format.pdf do
        ws = Worksheet.find(params.require(:id))
        pdf = ws.sheet
        send_data pdf.render, filename:
        "odl_nr_#{ws.number}.pdf",
        type: "application/pdf"
      end
    end
  end

  def index
    unless params[:list].nil?
      unless params[:list][:search].nil?
        @search_list = params[:list][:search]
      end
    end

    begin
      respond_to do |format|
        format.html { render 'workshop/index' }
        format.js { render partial: 'workshop/index_js' }
      end
    rescue Exception => e
      respond_to do |format|
        @error = e.message+"\n"+e.backtrace.join("\n")
        format.html { render partial: 'layouts/error_html' }
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def reset_worksheet
    begin
      odl = EurowinController::get_worksheet(@worksheet.number)
      EurowinController::reset_odl(@worksheet.number)
      # EurowinController::create_worksheet({
      #   'DataEntrataVeicolo': '-1',
      #   'AnnoODL': odl['Anno'].to_s,
      #   'ProtocolloODL': odl['Protocollo'].to_s,
      #   'DataIntervento': odl['DataIntervento']
      #   })
      @worksheet.update(opening_date: nil, paused: true, last_starting_time: nil, last_stopping_time: nil, real_duration: 0)
      @worksheet.workshop_operations.each{ |wo| wo.delete}
      respond_to do |format|
        if params[:area] == 'on_processing'
          format.js { render partial: 'workshop/worksheet_op_js' }
        else
          format.js { render partial: 'workshop/close_worksheet_js' }
        end
        # format.js { redirect_to worksheets_path }
      end
    rescue Exception => e
      @error = e.message+"\n\n#{e.backtrace}"
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def open_notification

    begin
      # Get worksheet from vehicle
      vehicle = MssqlReference.where("remote_object_id = #{params.require(:vehicle)} and (local_object_type = 'Vehicle' or local_object_type = 'ExternalVehicle')").first.local_object

      # Get first open worksheet
      # @worksheet = Worksheet.where(vehicle: vehicle, closed: false, exit_time: nil).where().order(opening_date: :asc).first
      odl = EurowinController::get_last_open_odl_by_vehicle(params.require(:vehicle))

      # Get the notification
      sgn = EurowinController::get_notification(params.require(:sgn))

      if odl.nil?


        vehicle_refs = EurowinController::get_vehicle(vehicle)

        payload = {
          'Descrizione': sgn['DescrizioneSegnalazione'],
          'ProtocolloODL': '0',
          'AnnoODL': '0',
          'DataEntrataVeicolo': Time.now.strftime('%Y-%m-%d'),
          'CodiceAutista': current_user.person.mssql_references.first.remote_object_id.to_s,
          'CodiceAutomezzo': vehicle_refs['CodiceAutomezzo'],
          'CodiceTarga': vehicle_refs['Targa'],
          'Chilometraggio': vehicle_refs['Km'].to_s,
          'CodiceOfficina': EurowinController::get_workshop(:workshop),
          'TipoDanno': sgn['TipoDanno'],
          'FlagSvolto': 'false'
        }

        odl = EurowinController::create_worksheet(payload)

        damage_type = EurowinController::get_tipo_danno(sgn['TipoDanno'],true)
        @worksheet  = Worksheet.create(code: "EWC*#{odl['Protocollo']}",vehicle: vehicle, notes: damage_type['Descrizione']+" - "+sgn['DescrizioneSegnalazione'], opening_date: Date.current, log: "Scheda creata da #{current_user.person.list_name}, il #{Time.now.strftime("%d/%m/%Y alle %H:%M:%S")}.\n")


        vec = vehicle.vehicle_checks('workshop')
        if vec.size < 1
          raise "Non ci sono controlli da fare per questo mezzo (targa: #{v.plate})."
        end

        if vehicle.class == ExternalVehicle

          @check_session = VehicleCheckSession.create(date: Date.today,external_vehicle: vehicle, operator: current_user, theoretical_duration: vehicle.vehicle_checks('workshop').map{ |c| c.duration }.inject(0,:+), log: "Sessione iniziata da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.", myofficina_reference: @worksheet.number.to_i, worksheet: @worksheet, station: @station)

        elsif vehicle.class == Vehicle

          @check_session = VehicleCheckSession.create(date: Date.today,vehicle: vehicle, operator: current_user, theoretical_duration: vehicle.vehicle_checks('workshop').map{ |c| c.duration }.inject(0,:+), log: "Sessione iniziata da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.", myofficina_reference: @worksheet.number.to_i, worksheet: @worksheet, station: @station)

        end
        @checks = Hash.new
        vec.each do |vc|
          @checks[vc.code] = Array.new if @checks[vc.code].nil?
          @checks[vc.code] << VehiclePerformedCheck.create(vehicle_check_session: @check_session, vehicle_check: vc, value: nil, notes: nil, performed: 0, mandatory: vehicle.mandatory?(vc) )
        end
      else
        @worksheet = Worksheet.find_by(code: "EWC*#{odl['Protocollo']}")
      end

      payload = {
        'ProtocolloODL': odl['Protocollo'].to_s,
        'AnnoODL': odl['Anno'].to_s,
        'ProtocolloSGN': sgn['Protocollo'].to_s,
        'AnnoSGN': sgn['Anno'].to_s,
        'CodiceAutomezzo': params.require(:vehicle).to_s,
        'CodiceOfficina': EurowinController::get_workshop(:workshop),
        'FlagRiparato': 'false',
        'FlagStampato': 'false',
        'FlagChiuso': 'false'
      }

      sgn = EurowinController::create_notification(payload)
      # WorkshopOperation.create(name: 'Lavorazione', worksheet: @worksheet, myofficina_reference: sgn['Protocollo'], user: current_user, log: "Operazione creata da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.")
      #
      # respond_to do |format|
      #   format.js { render partial: 'workshop/worksheet_js' }
      # end
      open_worksheet
    rescue Exception => e
      @error = e.message+"\n\n#{e.backtrace}"
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def open_worksheet

    begin
      if @worksheet.mileage.to_i == 0
        @worksheet.update(mileage: @worksheet.vehicle.mileage)
      end
      if @worksheet.opening_date.nil?
        @worksheet.update(opening_date: Date.today, log: @worksheet.log.to_s+"\nScheda aperta da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.")

        odl = EurowinController::get_worksheet(@worksheet.number)
        EurowinController::create_worksheet('DataEntrataVeicolo': Date.today.strftime('%Y-%m-%d'),'AnnoODL': odl['Anno'].to_s, 'ProtocolloODL': odl['Protocollo'].to_s, 'DataIntervento': odl['DataIntervento'])
      else
        @worksheet.update(log: @worksheet.log.to_s+"\nScheda riaperta da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.")
      end
      @worksheet.notifications.each do |sgn|
        if WorkshopOperation.to_notification(sgn['Protocollo']).count < 1
          WorkshopOperation.create(name: "Lavorazione", worksheet: @worksheet, myofficina_reference: sgn['Protocollo'], user: current_user, log: "Operazione creata da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.")
        end
      end
      WorkshopOperation.create(name: 'Controlli', worksheet: @worksheet, myofficina_reference: nil) if @worksheet.check_operations.count < 1

      v = @worksheet.vehicle
      vec = v.vehicle_checks('workshop')
      if vec.size < 1
        raise "Non ci sono controlli da fare per questo mezzo (targa: #{v.plate})."
      end

      if @check_session.nil?
        if v.class == ExternalVehicle

          @check_session = VehicleCheckSession.create(date: Date.today,external_vehicle: v, operator: current_user, theoretical_duration: v.vehicle_checks('workshop').map{ |c| c.duration }.inject(0,:+), log: "Sessione iniziata da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.", myofficina_reference: @worksheet.number.to_i, worksheet: @worksheet, station: @station)

        elsif v.class == Vehicle

          @check_session = VehicleCheckSession.create(date: Date.today,vehicle: v, operator: current_user, theoretical_duration: v.vehicle_checks('workshop').map{ |c| c.duration }.inject(0,:+), log: "Sessione iniziata da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.", myofficina_reference: @worksheet.number.to_i, worksheet: @worksheet, station: @station)

        end

        @checks = Hash.new
        vec.each do |vc|
          @checks[vc.code] = Array.new if @checks[vc.code].nil?
          @checks[vc.code] << VehiclePerformedCheck.create(vehicle_check_session: @check_session, vehicle_check: vc, value: nil, notes: nil, performed: 0, mandatory: v.mandatory?(vc) )
        end

      else

        @check_session.update(log: @check_session.log.to_s+"\nSessione ripresa da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.")

      end
      @worksheet.update(last_starting_time: Time.now, last_stopping_time: nil, paused: false)

      respond_to do |format|
        format.js { render partial: 'workshop/worksheet_js' }
      end
    rescue Exception => e
      @error = e.message+"\n\n#{e.backtrace}"
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def info_worksheet
    begin
      @vehicle = @worksheet.vehicle
      respond_to do |format|
        format.js { render partial: 'workshop/infobox_worksheet' }
      end
    rescue Exception => e
      @error = e.message+"\n\n#{e.backtrace}"
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def create_operation
    begin
      WorkshopOperation.create(name: params.require('name'), worksheet: @worksheet, myofficina_reference: @protocol == 'checks' ? nil : @protocol, user: current_user, log: "Operazione creata da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.")
      respond_to do |format|
        format.js { render partial: 'workshop/worksheet_js' }
      end
    rescue Exception => e
      @error = e.message+"\n\n#{e.backtrace}"
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def create_notification
    begin
      vehicle_refs = EurowinController::get_vehicle(@worksheet.vehicle)
      payload = {
        'Descrizione': params.require('description'),
        'ProtocolloODL': params.require('protocol'),
        'AnnoODL': Date.current.strftime('%Y'),
        'UserInsert': current_user.person.complete_name.upcase.gsub("'","\'"),
        'UserPost': 'OFFICINA',
        'CodiceAutista': current_user.person.mssql_references.first.remote_object_id.to_s,
        'CodiceAutomezzo': vehicle_refs['CodiceAutomezzo'],
        'CodiceTarga': vehicle_refs['Targa'],
        'Chilometraggio': vehicle_refs['Km'].to_s,
        'CodiceOfficina': EurowinController::get_workshop(:workshop),
        'FlagRiparato': 'false',
        'FlagStampato': 'false',
        'FlagChiuso': 'false'
      }

      sgn = EurowinController::create_notification(payload)
      WorkshopOperation.create(name: 'Lavorazione', worksheet: @worksheet, myofficina_reference: sgn['Protocollo'], user: current_user, log: "Operazione creata da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.")
      respond_to do |format|
        format.js { render partial: 'workshop/worksheet_js' }
      end
    rescue Exception => e
      @error = e.message+"\n\n#{e.backtrace}"
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def create_worksheet
    begin
      if params['Worksheet']['vehicle'].nil? || params['Worksheet']['vehicle'] == ''
        vehicle = Vehicle.find_by_plate(params.require('Worksheet')['vehicle_plate'].gsub(' ',''))
      else
        vehicle = params.require('Worksheet').permit(:model_name) == 'ExternalVehicle' ? ExternalVehicle.find(params.require('Worksheet').permit(:vehicle)['vehicle'].to_i) : Vehicle.find(params.require('Worksheet').permit(:vehicle)['vehicle'].to_i)
      end

      vehicle_refs = EurowinController::get_vehicle(vehicle)

      payload = {
        'Descrizione': params.require('Worksheet').permit('description')['description'],
        'ProtocolloODL': '0',
        'AnnoODL': '0',
        'DataEntrataVeicolo': Time.now.strftime('%Y-%m-%d'),
        'CodiceAutista': current_user.person.mssql_references.first.remote_object_id.to_s,
        'CodiceAutomezzo': vehicle_refs['CodiceAutomezzo'],
        'CodiceTarga': vehicle_refs['Targa'],
        'Chilometraggio': vehicle_refs['Km'].to_s,
        'CodiceOfficina': EurowinController::get_workshop(:workshop),
        'TipoDanno': params.require('Worksheet').permit(:damage_type)['damage_type'],
        'FlagSvolto': 'false'
      }

      odl = EurowinController::create_worksheet(payload)

      damage_type = EurowinController::get_tipo_danno(params.require('Worksheet').permit(:damage_type)['damage_type'],true)
      @worksheet  = Worksheet.create(code: "EWC*#{odl['Protocollo']}",vehicle: vehicle, notes: damage_type['Descrizione']+" - "+params.require('Worksheet').permit('description')['description'], opening_date: Date.current, log: "Scheda creata da #{current_user.person.list_name}, il #{Time.now.strftime("%d/%m/%Y alle %H:%M:%S")}.\n")


      vec = vehicle.vehicle_checks('workshop')
      if vec.size < 1
        raise "Non ci sono controlli da fare per questo mezzo (targa: #{v.plate})."
      end

      if vehicle.class == ExternalVehicle

        @check_session = VehicleCheckSession.create(date: Date.today,external_vehicle: vehicle, operator: current_user, theoretical_duration: vehicle.vehicle_checks('workshop').map{ |c| c.duration }.inject(0,:+), log: "Sessione iniziata da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.", myofficina_reference: @worksheet.number.to_i, worksheet: @worksheet, station: @station)

      elsif vehicle.class == Vehicle

        @check_session = VehicleCheckSession.create(date: Date.today,vehicle: vehicle, operator: current_user, theoretical_duration: vehicle.vehicle_checks('workshop').map{ |c| c.duration }.inject(0,:+), log: "Sessione iniziata da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.", myofficina_reference: @worksheet.number.to_i, worksheet: @worksheet, station: @station)

      end
      @checks = Hash.new
      vec.each do |vc|
        @checks[vc.code] = Array.new if @checks[vc.code].nil?
        @checks[vc.code] << VehiclePerformedCheck.create(vehicle_check_session: @check_session, vehicle_check: vc, value: nil, notes: nil, performed: 0, mandatory: vehicle.mandatory?(vc) )
      end


      respond_to do |format|
        format.js { render partial: 'workshop/worksheet_js' }
      end
    rescue Exception => e
      @error = e.message+"\n\n#{e.backtrace}"
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def deassociate_notification
    begin

      # update worksheet's log
      @worksheet.update(log: "#{@worksheet.log}\n Segnalazione '#{params.require('description')}' (#{params.require('protocol')}) spostata da #{current_user.person.list_name} il #{Time.now.strftime("%Y/%m/%d")} alle #{Time.now.strftime("%H:%M:%S")}.")

      vehicle_refs = EurowinController::get_vehicle(@worksheet.vehicle)
      if params['external_workshop'].nil?
        odl = EurowinController::last_open_odl_not(@worksheet.number)

        odl = EurowinController::create_worksheet({
          'Descrizione': params.require('description'),
          'ProtocolloODL': "0",
          'AnnoODL': "0",
          'CodiceAutomezzo': vehicle_refs['CodiceAutomezzo'],
          'CodiceAutista': vehicle_refs['CodiceAutista'],
          'CodiceTarga': vehicle_refs['Targa'],
          'Chilometraggio': vehicle_refs['Km'].to_s,
          'TipoDanno': params.require('damage_type').to_s,
          'CodiceOfficina': EurowinController::get_workshop(:workshop),
          'FlagSvolto': 'false'
          }) if odl.nil?
        protocollo_odl = odl['Protocollo'].to_s
        anno_odl = odl['Anno'].to_s

      else
        odl = "-1"
        anno_odl = "-1"

      end

      duplicate_sgn = nil
      # Stop or delete all operations
      wos = WorkshopOperation.get_from_sgn(params.require('protocol'))

      wos.each do |wo|
        if wo.real_duration.to_i == 0
          wo.delete
          next
        end
        if wo.paused
          duration = wo.real_duration
        else
          duration = wo.real_duration + Time.now.to_i - wo.last_starting_time.to_i
        end
        wo.update(ending_time: DateTime.now, real_duration: duration, paused: true, last_starting_time: nil, last_stopping_time: Time.now, log: "#{wo.log}\n Operazione conclusa da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.", notes: params['notes'].tr("'","''"))
        # @worksheet.update(real_duration: params.require('worksheet_duration').to_i)
        @worksheet.update(last_starting_time: Time.now, last_stopping_time: nil, real_duration: @worksheet.real_duration + Time.now.to_i - @worksheet.last_starting_time.to_i, paused: false) unless @worksheet.paused
        @worksheet.update(log: "#{@worksheet.log}\n #{wo.log}")
        #close notification there are no more operations
        duplicate_sgn = wo.ew_notification
      end

      if duplicate_sgn.nil?

        sgn = EurowinController::create_notification({
          'Descrizione': params.require('description'),
          'ProtocolloODL': protocollo_odl,
          'AnnoODL': anno_odl,
          'ProtocolloSGN': params.require('protocol'),
          'AnnoSGN': params.require('year'),
          'UserInsert': current_user.person.complete_name.upcase,
          'UserPost': 'OFFICINA',
          'CodiceAutista': current_user.person.mssql_references.first.remote_object_id.to_s,
          'CodiceAutomezzo': vehicle_refs['CodiceAutomezzo'],
          'CodiceTarga': vehicle_refs['Targa'],
          'Chilometraggio': vehicle_refs['Km'].to_s,
          'TipoDanno': params.require('damage_type').to_s,
          'CodiceOfficina': EurowinController::get_workshop(:workshop),
          'FlagStampato': 'false'
        })

      else

        EurowinController::create_notification({
          'ProtocolloODL': duplicate_sgn['SchedaInterventoProtocollo'].to_s,
          'AnnoODL': duplicate_sgn['SchedaInterventoAnno'].to_s,
          'ProtocolloSGN': duplicate_sgn['Protocollo'].to_s,
          'AnnoSGN': duplicate_sgn['Anno'].to_s,
          'DataIntervento': duplicate_sgn['DataSegnalazione'].to_s,
          'FlagRiparato': 'false',
          'FlagSvolto': 'true',
          'CodiceOfficina': "0"
        })

        sgn = EurowinController::create_notification({
          'Descrizione': params.require('description'),
          'ProtocolloODL': protocollo_odl,
          'AnnoODL': anno_odl,
          'ProtocolloSGN': '-1',
          'AnnoSGN': '-1',
          'UserInsert': current_user.person.complete_name.upcase,
          'UserPost': 'OFFICINA',
          'CodiceAutista': current_user.person.mssql_references.first.remote_object_id.to_s,
          'CodiceAutomezzo': vehicle_refs['CodiceAutomezzo'],
          'CodiceTarga': vehicle_refs['Targa'],
          'Chilometraggio': vehicle_refs['Km'].to_s,
          'TipoDanno': params.require('damage_type').to_s,
          'CodiceOfficina': EurowinController::get_workshop(:workshop),
          'FlagStampato': 'false'
        })
      end

      respond_to do |format|
        if params[:area].nil?
          format.js { render partial: 'workshop/worksheet_js' }
        elsif params[:area] == 'on_processing'
          @notifications = @worksheet.notifications(:all)
          format.js { render partial: 'workshop/xbox_js' }
        end
      end
    rescue Exception => e
      @error = e.message+"\n\n#{e.backtrace}"
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def update_operation_time
    @worksheet.operations.each do |wo|
      wo.update(real_duration: wo.real_duration.to_i + Time.now.to_i - wo.last_starting_time.to_i , last_starting_time: Time.now) unless wo.paused
    end

    # @worksheet.update(last_starting_time: Time.now, last_stopping_time: nil, real_duration: @worksheet.real_duration.to_i + Time.now.to_i - @worksheet.last_starting_time.to_i, paused: false) unless @worksheet.paused
    respond_to do |format|
      format.js { render partial: 'workshop/worksheet_js' }
    end
  end

  def start_operation
    begin
      wo = WorkshopOperation.find(params.require(:operation).to_i)

      #if the current user is different from the registered one create a new operation
      if !wo.nil? && wo.user != current_user
        if wo.user.nil?
          wo.update(name: wo.name, paused: false, worksheet: wo.worksheet, myofficina_reference: wo.myofficina_reference, user: current_user, starting_time: Time.now, last_starting_time: Time.now, log: "Operazione creata da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.")
        else
          WorkshopOperation.create(name: wo.name, paused: false, worksheet: wo.worksheet, myofficina_reference: wo.myofficina_reference, user: current_user, starting_time: Time.now, last_starting_time: Time.now, log: "Operazione creata da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.")
        end
      else
        @workshop_operation.update(ending_time: nil, paused: false, last_starting_time: Time.now, log: "#{@workshop_operation.log}\n Operazione #{wo.starting_time.nil?? 'iniziata' : 'ripresa'} da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.")
        # @workshop_operation.update(starting_time: DateTime.now)
        @worksheet.update(last_starting_time: Time.now, last_stopping_time: nil, real_duration: @worksheet.real_duration + Time.now.to_i - @worksheet.last_starting_time.to_i, paused: false) unless @worksheet.paused

      end
      respond_to do |format|
        format.js { render partial: 'workshop/worksheet_js' }
      end
    rescue Exception => e
      @error = e.message+"\n\n#{e.backtrace}"
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def pause_operation
    begin
      if @workshop_operation.paused
        duration = @workshop_operation.real_duration
      else
        duration = @workshop_operation.real_duration + Time.now.to_i - @workshop_operation.last_starting_time.to_i
      end
      @workshop_operation.update(real_duration: duration, paused: true,  last_starting_time: nil, last_stopping_time: Time.now, log: "#{@workshop_operation.log}\n Operazione interrotta da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.")
      # @worksheet.update(real_duration: params.require('worksheet_duration').to_i)
      @worksheet.update(last_starting_time: Time.now, last_stopping_time: nil, real_duration: @worksheet.real_duration + Time.now.to_i - @worksheet.last_starting_time.to_i, paused: false) unless @worksheet.paused
      respond_to do |format|
        format.js { render partial: 'workshop/worksheet_js' }
      end
    rescue Exception => e
      @error = e.message+"\n\n#{e.backtrace}"
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def finish_operation
    begin
      if @workshop_operation.paused
        duration = @workshop_operation.real_duration
      else
        duration = @workshop_operation.real_duration + Time.now.to_i - @workshop_operation.last_starting_time.to_i
      end
      @workshop_operation.update(ending_time: DateTime.now, real_duration: duration, paused: true, last_starting_time: nil, last_stopping_time: Time.now, log: "#{@workshop_operation.log}\n Operazione conclusa da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.", notes: params['notes'].tr("'","''"))
      # @worksheet.update(real_duration: params.require('worksheet_duration').to_i)
      @worksheet.update(last_starting_time: Time.now, last_stopping_time: nil, real_duration: @worksheet.real_duration + Time.now.to_i - @worksheet.last_starting_time.to_i, paused: false) unless @worksheet.paused
      @worksheet.update(log: "#{@worksheet.log}\n #{@workshop_operation.log}")
      #close notification there are no more operations
      if !@workshop_operation.myofficina_reference.nil? && WorkshopOperation.where(myofficina_reference: @workshop_operation.myofficina_reference).select{|wo| wo.ending_time.nil?}.size < 1
        EurowinController::create_notification({
          'ProtocolloODL': @workshop_operation.ew_notification['SchedaInterventoProtocollo'].to_s,
          'AnnoODL': @workshop_operation.ew_notification['SchedaInterventoAnno'].to_s,
          'ProtocolloSGN': @workshop_operation.ew_notification['Protocollo'].to_s,
          'AnnoSGN': @workshop_operation.ew_notification['Anno'].to_s,
          'DataIntervento': @workshop_operation.ew_notification['DataSegnalazione'].to_s,
          'FlagRiparato': 'true',
          'CodiceOfficina': "0"
        })
      end

      respond_to do |format|
        if params[:area].nil?
          format.js { render partial: 'workshop/worksheet_js' }
        elsif params[:area] == 'on_processing'
          @notifications = @worksheet.notifications(:all)
          format.js { render partial: 'workshop/xbox_js' }
        end
      end
    rescue Exception => e
      @error = e.message+"\n\n#{e.backtrace}"
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def delete_operation
    begin
      @worksheet.update(log: "#{@worksheet.log}\n Operazione nr. #{@workshop_operation.id}, '#{@workshop_operation.name}', eliminata da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.")
      if @workshop_operation.siblings.count < 2
        @workshop_operation.update(user: nil)
      else
        @workshop_operation.destroy
      end
      respond_to do |format|
        format.js { render partial: 'workshop/worksheet_js' }
      end
    rescue Exception => e
      @error = e.message+"\n\n#{e.backtrace}"
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def save_worksheet
    begin
      # JSON.parse(params.require('operation_times')).each do |ot|
      #   WorkshopOperation.find(ot['id'].to_i).update(real_duration: ot['time'].to_i)
      # end

      # if @worksheet.last_starting_time.nil?
      #   duration = @worksheet.real_duration
      # else
      #   duration = @worksheet.real_duration + Time.now.to_i - @worksheet.last_starting_time.to_i
      # end

      duration = @worksheet.workshop_operations.map{ |wo| wo.real_duration}.inject(0,:+)
      if params[:area] == 'on_processing' || current_user.has_role?('amministratore officina')
        ops = @worksheet.operations
      else
        ops = @worksheet.operations(current_user)
      end
      ops.each do |wo|
        wo.update(real_duration: wo.real_duration + Time.now.to_i - wo.last_starting_time.to_i , last_stopping_time: Time.now, last_starting_time: nil, paused: true) unless wo.paused
      end

      @worksheet.update(last_starting_time: nil, last_stopping_time: Time.now, real_duration: duration, paused: true)
      if params.require('perform') == 'stop'
        ops.each do |wo|
          wo.update(ending_time: Time.now)
          unless wo.myofficina_reference.nil?
            sgn = EurowinController::get_notification(wo.myofficina_reference)
            EurowinController::create_notification({
              'ProtocolloODL': sgn['SchedaInterventoProtocollo'].to_s,
              'AnnoODL': sgn['SchedaInterventoAnno'].to_s,
              'ProtocolloSGN': sgn['Protocollo'].to_s,
              'AnnoSGN': sgn['Anno'].to_s,
              'DataIntervento': sgn['DataSegnalazione'].to_s,
              'FlagRiparato': 'true',
              'CodiceOfficina': "0"
            })
          end
        end
        invoicing = params['invoice'] == 'true' ? true : false

        @worksheet.update(invoicing: invoicing, exit_time: DateTime.now, log: "#{@worksheet.log}\n Scheda chiusa da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.")
        vcs = @worksheet.vehicle_check_session
        vcs.update(finished: DateTime.now, real_duration: 0, log: vcs.log.to_s+"\nSessione conclusa da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.") unless vcs.nil?
        odl = @worksheet.ew_worksheet
        EurowinController::create_worksheet({
          'ProtocolloODL': odl['Protocollo'].to_s,
          'AnnoODL': odl['Anno'].to_s,
          'DataIntervento': odl['DataIntervento'].to_s,
          'DataUscitaVeicolo': Date.today.strftime("%Y-%m-%d"),
          'FlagSvolto': 'true',
          'CodiceOfficina': "0"
        }) unless odl.nil?
        @worksheet.output_orders.each do |oo|
          oo.update(processed: true)
        end
        pdf = @worksheet.sheet
        unless pdf.nil?
          # File.open("/mnt/documents/ODL/#{@worksheet.vehicle.plate}/ODL_#{@worksheet.number}.pdf",'w').write(pdf.render.force_encoding('utf-8'))
          @worksheet.write_sheet
          WorkshopMailer.send_worksheet(@worksheet,pdf).deliver_now
        end
        WorkshopMailer.send_to_logistics(@worksheet).deliver_now
      else
        # @worksheet.update(last_starting_time: nil, last_stopping_time: Time.now, real_duration: @worksheet.real_duration + Time.now.to_i - @worksheet.last_starting_time.to_i, paused: true)
      end

      respond_to do |format|
        if params[:area] == 'on_processing'
          format.js { render partial: 'workshop/worksheet_op_js' }
        elsif @station.to_s == 'carwash'
          format.js { render 'carwash/checks_index_js' }
        else
          format.js { render partial: 'workshop/close_worksheet_js' }
        end
        # format.js { redirect_to worksheets_path }
      end
    rescue Exception => e

      @error = "WorkshopController.rb 656\n\n"+e.message+"\n\n\n"+e.backtrace.join("\n\n")
      ErrorMailer.error_report(@error,"Chiusura scheda - ODL nr. #{@worksheet.number}").deliver_now
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  private

  def get_worksheet
    @worksheet = Worksheet.find_or_create_by_code(params.require(:id))
  end

  def get_check_session
    @check_session = VehicleCheckSession.find_by(worksheet: @worksheet)
    @checks = @check_session.vehicle_ordered_performed_checks unless @check_session.nil?
  end

  def get_workshop_operation
    @workshop_operation = WorkshopOperation.find(params.require(:operation).to_i)
  end

  def set_protocol
    if params['protocol'] == 'checks'
      @protocol = 'checks'
    else
      @protocol = params['protocol'].to_i
    end
  end

  def set_station
    @station = params['station'].nil? ? 'workshop' : params['station']
  end

end
