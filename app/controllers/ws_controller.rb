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
    MdcUser.assigned.each do |p|
      r = mdc.get_fares_data({applicationID: 'FARES', deviceCode: p.user.upcase, status: @status}).reverse[0,10]
      @results << r unless r.empty?
    end
    mdc.close_session
    render 'mdc/index'
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
        id = params.require(:id)
        msg = Base64.decode64(params.require('ChatMessage'))
        mdc = MdcWebservice.new
        mdc.begin_transaction
        mdc.delete_tabgen_by_selector([TabgenSelector.new({tabname: 'FARES', index: 0, value: id, deviceCode: ''})])
        mdc.insert_or_update_tabgen(Tabgen.new({deviceCode: "|#{user.user.upcase}|", key: id, order: 0, tabname: 'FARES', values: [msg]}))
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
        mdc.send_same_push_notification_ext((MdcUser.assigned.to_a - [user]),'Aggiornamento viaggi.')
        mdc.send_push_notification_ext([user],msg,nil)
        mdc.commit_transaction
        mdc.end_transaction
        mdc.close_session
        @msg = "Messaggio inviato. Targa: #{params[:VehiclePlateNumber]}, #{user.holder.complete_name} (utente: #{user.user})."
      end
    else
      @msg = "Messaggio non inviato. Targa: #{params[:VehiclePlateNumber]}, #{Base64.decode64(params.require(:driver))} o #{Base64.decode64(params.require(:company))}non esistono."
    end

    render :partial => 'layouts/messages'
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
        send_data pdf.render, filename:
        "test.pdf",
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
      p = params.require('reports').permit(:date_from, :date_to, :types => [])
    end

    # Set dates
    @date_to = Date.strptime(p[:date_to],"%Y-%m-%d")
    @date_from = Date.strptime(p[:date_from],"%Y-%m-%d")

    # Set correct types
    @types = {
      'guasto': false,
      'furto': false,
      'dpi': false,
      'contravvenzione': false,
      'sosta_prolungata': false,
      'incidente': false,
      'infortunio': false
    }

    p[:types].each do |t|
      @types[t] = true
    end

    # Run query
    MdcReport.where("sent_at between '#{@date_from.strftime("%Y%m%d")}' and '#{@date_to.strftime("%Y%m%d")}'")
            .where("#{@office} = 1")
            .where("report_type in (#{@types.select{ |t| t }.map{ |k,t| "'#{k}'"}.join(',')})")
            .order(sent_at: :desc)

  end

  # Set defaults for report filter
  def get_filter_defaults

    case @office
    when 'maintenance' then
      p = {types: ['guasto','furto']}
    when 'logistics' then
      p = {types: ['furto','dpi','contravvenzione','sosta_prolungata','incidente','infortunio']}
    when 'hr' then
      p = {types: ['furto','dpi','incidente','infortunio']}
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

end
