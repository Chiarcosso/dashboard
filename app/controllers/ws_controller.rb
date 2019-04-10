class WsController < ApplicationController
  skip_before_action :authenticate_user!, :only => :update_fares
  protect_from_forgery except: :update_fares
  before_action :set_status, :only => [:index]
  before_action :get_action, only: [:update_user]
  before_action :get_holder, only: [:update_user]

  def autocomplete_person_company
    array = Company.filter(params.permit(:term)[:term]).map{ |p| { id: p.id.to_s, label: p.list_name, value: p.class.to_s+'#'+p.list_name, name: p.name} }
    array += Person.filter(params.permit(:term)[:term]).map{ |p| { id: p.id.to_s, label: p.list_name, value: p.class.to_s+'#'+p.list_name, name: p.name} }

    render :json => array
  end

  def index
    mdc = MdcWebservice.new

    @results = Array.new
    # @results << mdc.get_fares_data({applicationID: 'FARES', deviceCode: '', status: @status}).reverse[0,10]
    # byebug
    MdcUser.assigned.each do |p|
      r = mdc.get_fares_data({applicationID: 'FARES', deviceCode: p.user.upcase, status: @status}).reverse[0,10]
      @results << r unless r.empty?
    end
    mdc.close_session
    render 'mdc/index'
  end

  # Create notification from MDC report
  def create_notification

    # Get report and vehicle from params
    MdcReport.find(params.require(:id).to_i).create_notification(current_user)

    @results = get_filter
    respond_to do |format|
      format.js {render partial: 'mdc/report_index_js'}
    end
  end

  # GET request action
  def notification_index
    @results = get_filter
    respond_to do |format|
      format.html {render 'mdc/report_index'}
      format.js {render partial: 'mdc/report_index_js'}
    end
  end

  # POST (JS) request action
  def notification_filter
    @results = get_filter
    respond_to do |format|
      format.html {render partial: 'mdc/report_index'}
      format.js {render partial: 'mdc/report_index_js'}
    end

  end

  def codes
    render 'mdc/codes_index'
  end

  def create_user
    u = params.require(:user)
    a = params.require(:activation_code) unless params[:activation_code] == ''
    person = nil
    if MdcUser.find_by(user: u).nil? and params[:activation_code] != ''
      # Person.mdc.each do |p|
      #   if p.mdc_user == u.downcase
      #     person = p
      #     break
      #   end
      # end
      MdcUser.create(:user => params.require(:user).upcase, :activation_code => params.require(:activation_code), :assigned_to_person => person )
    end
    render 'mdc/codes_index'
  end

  def update_user
    unless @code.nil?
      case @action
      when :edit
        if @holder.class == Person
          @holder.rearrange_mdc_users @code.user
          @code.update(activation_code: params.require(:mdc_activation_code), assigned_to_person: @holder, assigned_to_company: nil)
        elsif @holder.class == Company
          p = Person.find_by_mdc_user(@code.user)
          p.rearrange_mdc_users nil unless p.nil?
          @code.update(activation_code: params.require(:mdc_activation_code), assigned_to_company: @holder, assigned_to_person: nil)
        end
      when :delete
        @code.destroy
      end
      # @msg = 'Codice creato.'
    else
      # @msg = 'Codice esistente.'
    end
    respond_to do |format|
      format.js { render :partial => 'mdc/users_list_js' }
    end
  end

  def close_fare
    mdc = MdcWebservice.new
    mdc.begin_transaction
    mdc.update_data_collection_rows_status(Base64.decode64(params.require(:data_collection_rows)))
    mdc.delete_tabgen_by_selector([TabgenSelector.new({tabname: 'FARES', index: 0, value: params.require(:id), deviceCode: ''})])
    # Person.mdc.each do |p|
    #   mdc.send_push_notification([p.mdc_user],'Aggiornamento viaggi.')
    # end
    mdc.send_same_push_notification_ext(MdcUser.assigned.to_a,'Chiusura viaggio.')
    # MdcUser.assigned.each do |mdcu|
    #   mdc.send_push_notification_ext([mdcu],'Aggiornamento viaggi.',nil)
    # end
    # mdc.send_push_notification(['ALL'],'Aggiornamento viaggi.')
    # mdc.send_push_notification(Person.mdc.pluck(:mdc_user),'Aggiornamento viaggi.')
    mdc.commit_transaction
    mdc.end_transaction
    mdc.close_session
    @status = 0
    index
  end

  def self.update_plates

    mdc = MdcWebservice.new
    mdc.begin_transaction
    # tb = mdc.select_tabgen(Tabgen.new({deviceCode: "All user", key: '', order: 0, tabname: 'VEHICLES_TMP'}))
    # byebug
    mdc.delete_tabgen_by_selector([TabgenSelector.new({tabname: 'RUNNING_VEHICLES', index: 0, value: '%', deviceCode: ""})])
    mdc.commit_transaction
    Vehicle.where(dismissed: false).where("property_id = #{Company.chiarcosso.id} or property_id = #{Company.transest.id}").reject{ |v| v.plate.nil? }.to_a.each do |v|

      # mdc.insert_or_update_tabgen(Tabgen.new({deviceCode: "|#{MdcUser.all.map{|mu| mu.user.upcase}.join('|')}|", key: v.id, order: 0, tabname: 'VEHICLES', values: [v.plate,v.vehicle_type.name]}))
       mdc.insert_or_update_tabgen(Tabgen.new({deviceCode: "__ALL__", key: v.id, order: 0, tabname: 'RUNNING_VEHICLES', values: [v.plate,v.vehicle_type.name]}))
      puts "#{v.id}:  #{v.plate} has been uploaded"
    end
    # mdc.send_same_push_notification_ext((MdcUser.assigned.to_a),'Aggiornamento veicoli.')
    mdc.commit_transaction
    mdc.end_transaction
    mdc.close_session

  end

  def update_fares
    # user = Person.find_by_complete_name(Base64.decode64(params.require(:driver)))
    user = MdcUser.find_by_holder(Base64.decode64(params.require(:driver))) || MdcUser.find_by_holder(Base64.decode64(params.require(:company)))
    unless user.nil?
      if user.assigned_to_person.nil? and user.assigned_to_company.nil?
        @msg = "Messaggio non inviato. Targa: #{params[:VehiclePlateNumber]}, #{user.holder.complete_name} non ha un utente assegnato."
      else
        sync_fares_table(
          msg: Base64.decode64(params.require('ChatMessage')),
          id: params.require(:id),
          user: user
        )
        @msg = "Messaggio inviato. Targa: #{params[:VehiclePlateNumber]}, #{user.holder.complete_name} (utente: #{user.user})."
      end
    else
      @msg = "Messaggio non inviato. Targa: #{params[:VehiclePlateNumber]}, #{Base64.decode64(params.require(:driver))} o #{Base64.decode64(params.require(:company))}non esistono."
    end

    render :partial => 'layouts/messages'
  end

  # Update FARES tabgen, send push notifications
  def sync_fares_table(opts)

    mdc = MdcWebservice.new
    mdc.begin_transaction
    mdc.delete_tabgen_by_selector([TabgenSelector.new({tabname: 'FARES', index: 0, value: opts[:id], deviceCode: ''})])
    mdc.insert_or_update_tabgen(Tabgen.new({deviceCode: "|#{opts[:user].user.upcase}|", key: opts[:id], order: 0, tabname: 'FARES', values: [opts[:msg]]}))
    # Person.mdc.each do |p|
    #   mdc.send_push_notification([p.mdc_user],'Aggiornamento viaggi.') unless p == driver
    # end
    # MdcUser.all.each do |p|
    #   mdc.send_push_notification([p.user],'Aggiornamento viaggi.') unless p == user
    # end
    # mdc.send_push_notification((MdcUser.all - [user]),'Aggiornamento viaggi.')
    # mdc.send_push_notification([user],msg)
    # MdcUser.assigned.each do |mdcu|
    #   mdc.send_push_notification_ext([mdcu],'Aggiornamento viaggi.',nil) unless mdcu == user
    # end
    mdc.send_same_push_notification_ext((MdcUser.assigned.to_a - [opts[:user]]),'Aggiornamento viaggi.')
    mdc.send_push_notification_ext([opts[:user]],opts[:msg],nil)
    mdc.commit_transaction
    mdc.end_transaction
    mdc.close_session
  end

  # Query MSSQL for new fares, eventually send them to the mdc app and mark its mdc check on MSSQL
  def self.send_fares_massive

    # Prepare client and query
    c = MssqlReference.get_client
    q = <<-QUERY
      select distinct
        IDPosizione,
        a.nominativo as driver,
        g.mdc,
        d.RagioneSociale as company,
        (
          convert(nvarchar,g.data,104)+
          +' '+
          +m.Targa+
          +' - '+
          +ISNULL(r.Targa,'')+
          +' '+
          +a.nominativo+
          +'\r\n'+
          +convert(nvarchar,g.ProgressivoGiornata)+
          +' - Partenza: '+
          +ISNULL(p.Descrizione,
            ISNULL(cc.[ditta partenza],'')+
            +' '+
            +ISNULL(cc.[via partenza],'')+
            +' '+
            +ISNULL(cc.[cap partenza],'')+
            +' '+
            +ISNULL(cc.partenza,g.partenza)+
            +' '+
            +ISNULL(cc.[provincia partenza],g.Pv)
          )

          +' Merce: '+
          +ISNULL(ma.merce,mg.merce)+
          +' '+
          +ISNULL(cc.[Descrivi Merce],'')+
          +' '+
          +ISNULL(cc.[ditta arrivo],'')+
          +' '+
          +ISNULL(cc.[via arrivo],'')+
          +' '+
          +ISNULL(cc.[cap arrivo],'')+
          +' '+
          +ISNULL(g.Scarico,ISNULL(cc.[arrivo],g.Destinazione))+
          +' '+
          +ISNULL(cc.[provincia arrivo],g.Pr)+
          +' '+
          +ISNULL(cc.note,'')+
          +' '+
          +ISNULL(g.RifCliente,'')
        ) as msg

      from giornale g

      left join autisti a ON g.idAutista = a.IDAutista
      left join [calcolo costi] cc ON g.idviaggi = cc.idviaggi
      left join materiali ma ON ma.idmerce = cc.merce
      left join materiali mg ON mg.idmerce = g.merce
      left join veicoli m ON g.idtarga = m.idveicolo
      left join rimorchi1 r ON g.idrimorchi = r.idrimorchio
      left join clienti co ON cc.cliente = co.idcliente
      left join clienti c ON g.idcliente = c.idcliente
      left join clienti d ON a.idFornitore = d.CodTraffico
      left join piazzali p ON g.IDPiazzaleSgancio = p.IDPiazzale

      where
        g.Data = '#{Time.now.strftime("%Y%m%d")}'
      and
        g.mdc != 1
      and
        g.ProgressivoGiornata between 1 and 9
      and
        g.IDCliente not in (9996,10336,9995,9997,9998,9985,10629,10630,10631,10632,9986,9989,2265,9994,9999);
    QUERY

    # Get fares
    fares = c.execute(q)

    # Log found trips
    special_logger.info("\r\n-------------------- Timely check: #{fares.count} trips found -------------------------\r\n")
    logistics_logger.info("\r\n-------------------- Timely check: #{fares.count} trips found -------------------------\r\n")

    # Loop through trips and send the ones that have a valid MDC user
    sent = 0
    fares.each do |fare|
      begin

        # Find user
        user = MdcUser.find_by_holder(fare['driver']) || MdcUser.find_by_holder(fare['company'])
        if user.nil?
          special_logger.info("[ #{fare['IDPosizione']} ] -- Trip discarded: #{fare['msg']}")
          logistics_logger.info("[ #{fare['IDPosizione']} ] -- Trip discarded: #{fare['msg']}")
          next
        end

        # Update table
        # sync_fares_table(
        #   msg: fare['msg'],
        #   id: fare['IDPosizione'],
        #   user: user
        # )

        # Set mdc flag in mssql
        # MssqlReference.get_client.execute(<<-QUERY
        #     update giornale set mdc = -1 where IDPosizione = #{fare['IDPosizione']}
        #   QUERY
        # )
        sent += 1
        special_logger.info("\n\n[ #{fare['IDPosizione']} ] -- Trip sent (#{user.holder.complete_name}): #{fare['msg']}\n\n")
        logistics_logger.info("\n\n[ #{fare['IDPosizione']} ] -- Trip sent (#{user.holder.complete_name}): #{fare['msg']}\n\n")

      rescue Exception => e
        special_logger.error("\r\n#{fare.inspect}\r\n\r\n#{e.message}\r\n")
        logistics_logger.error("\r\n#{fare.inspect}\r\n\r\n#{e.message}\r\n")
        next
      end
    end

    special_logger.info("\r\n----------------------- #{sent} trips sent ----------------------------\r\n")
    logistics_logger.info("\r\n----------------------- #{sent} trips sent ----------------------------\r\n")

  end

  def print_pdf
    photos = Array.new
    mdc = MdcWebservice.new
    params.require(:photos).each do |p|
      # p.sub!('http://chiarcosso.mobiledatacollection.it/','/var/lib/tomcat8/webapps/')
      p.sub!('http://outpost.chiarcosso/','/var/lib/tomcat8/webapps/')
      f = mdc.download_file(p).body[/Content-Type: image\/jpeg.?*\r\n\r\n(.?*)\r\n--MIMEBoundary/m,1]
      photos << f.force_encoding("utf-8") unless f.nil?
    end
    margins = 15
    pdf = Prawn::Document.new :filename=>'foo.pdf',
                          :page_size=> "A4",
                          :margin => margins

    photos.each do |p|
      file = File.open('tmp.jpg','w')
      file.write(p)
      file.close
      size = FastImage::size('tmp.jpg')

      unless size.nil?
        if size[0] > size[1]
            image = MiniMagick::Image.new("tmp.jpg")
            image.rotate(-90)
        end
      end
      pdf.image 'tmp.jpg', :fit => [595.28 - margins*2, 841.89 - margins*2]
    end
    mdc.close_session
    respond_to do |format|
      format.pdf do
        send_data pdf.render,
        filename: "#{params[:id]} #{params[:driver]}",
        type: "application/pdf"
      end
    end
  end

  private

  def set_status
    if params[:status] == 'opened' or params[:status].nil?
      @status = 0
    else
      @status = 1
    end
  end

  def get_holder
    if params.require(:holder_type) == 'Person'
      @holder = Person.find_by_complete_name(params.require(:holder))
    elsif params.require(:holder_type) == 'Company'
      @holder = Company.find_by_name(params.require(:holder))
    end
  end

  def get_filter
    # Build filter from params and run the resulting query

    @office = params.require(:office)

    return Array.new if @office.nil?


    if params[:reports].nil?
      # First call, no params, set filter to default
      p = get_filter_defaults
    else
      # Filter call, set filter to params
      p = params.require('reports').permit(:date_from, :date_to, :search, :types => [])
    end

    # Set dates
    @date_to = Date.strptime(p[:date_to],"%Y-%m-%d")
    @date_from = Date.strptime(p[:date_from],"%Y-%m-%d")

    # Set search
    @search = p[:search].to_s.tr("'","''")[0..255]

    # Set correct types
    @types = {
      'attrezzatura': false,
      'contravvenzione': false,
      'dpi': false,
      'furto': false,
      'guasto': false,
      'incidente': false,
      'infortunio': false,
      'sosta_prolungata': false
    }

    p[:types].each do |t|
      @types[t] = true
    end

    # Set up search to look in vehicles plates, drivers names, a report descriptions
    if @search == ''

      # Run query
      res = MdcReport.where("sent_at between '#{@date_from.strftime("%Y%m%d")}' and '#{@date_to.strftime("%Y%m%d")}'")
              .where("#{@office} = 1")
              .where("report_type in (#{@types.select{ |k,t| t }.map{ |k,t| "'#{k}'"}.join(',')})")
              .order(sent_at: :desc)

    else
      w = <<-SEARCH
          vehicle_id in
            (select v.id from vehicles v
              inner join vehicle_informations vi on vi.vehicle_id = v.id
              where vi.information like ? and vi.vehicle_information_type_id = #{VehicleInformationType.plate.id}
            )
          or mdc_reports.description like ?
          or mdc_reports.mdc_user_id in
            (select mdcu.id from mdc_users mdcu
              inner join people p on p.id = mdcu.assigned_to_person_id
              where (concat(p.name,' ',p.surname) like ? or concat(p.surname,' ',p.name) like ?)
            )
      SEARCH

      # Run query
      res = MdcReport.where("sent_at between '#{@date_from.strftime("%Y%m%d")}' and '#{@date_to.strftime("%Y%m%d")}'")
              .where("#{@office} = 1")
              .where("report_type in (#{@types.select{ |k,t| t }.map{ |k,t| "'#{k}'"}.join(',')})")
              .where(w,"%#{@search}%","%#{@search}%","%#{@search}%","%#{@search}%")
              .order(sent_at: :desc)
    end

  end

  # Set defaults for report filter
  def get_filter_defaults

    case @office
    when 'maintenance' then
      p = {types: ['attrezzatura','contravvenzione','furto','guasto','incidente']}
    when 'logistics' then
      p = {types: ['attrezzatura','contravvenzione','dpi','furto','sosta_prolungata','incidente','infortunio']}
    when 'hr' then
      p = {types: ['dpi','furto','incidente','infortunio']}
    end

    p[:date_from] = (Time.now - 48.hours).strftime("%Y-%m-%d")
    p[:date_to] = Time.now.strftime("%Y-%m-%d")

    return p
  end

  def get_action
    unless params[:id].nil?
      @code = MdcUser.find(params.require(:id).to_i)
    end
    case params.permit(:commit)[:commit]
    when 'Modifica'
        @action = :edit
      when 'Elimina'
        @action = :delete
    end
  end

  def self.logistics_logger
    @@logistics_logger ||= Logger.new("/mnt/wshare/Traffico/log_mdc/fares.log")
  end

  def self.special_logger
    @@fares_logger ||= Logger.new("#{Rails.root}/log/fares.log")
  end
end
