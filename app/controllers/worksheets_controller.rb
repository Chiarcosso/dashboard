class WorksheetsController < ApplicationController

  before_action :search_params

  def manage_worksheets_index
    begin
      apply_filter
      respond_to do |format|
        format.html { render 'worksheets/index' }
        format.js { render partial: 'worksheets/index_js' }
      end
    rescue Exception => e
      respond_to do |format|
        @error = e.message+"\n"+e.backtrace.join("\n")
        format.html { render partial: 'layouts/error_html' }
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def manage_external_worksheets_index
    begin
      apply_ow_filter
      respond_to do |format|
        format.html { render 'worksheets/index_other_workshops' }
        format.js { render partial: 'worksheets/index_other_workshops_js' }
      end
    rescue Exception => e
      respond_to do |format|
        @error = e.message+"\n"+e.backtrace.join("\n")
        format.html { render partial: 'layouts/error_html' }
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def on_processing_index
    begin
      # @open_worksheets = Worksheet.where("id in (select worksheet_id from workshop_operations where ending_time is null)").sort_by{|w| w.opening_date}
      respond_to do |format|
        format.html { render 'workshop/on_processing' }
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

  def notifications_xbox
    begin
      ws = get_worksheet
      @notifications = ws.notifications(:all)
      respond_to do |format|
        format.js { render partial: 'workshop/notifications_xbox' }
      end
    rescue Exception => e
      respond_to do |format|
        @error = e.message+"\n"+e.backtrace.join("\n")
        format.html { render partial: 'layouts/error_html' }
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def processing_xbox
    begin
      @worksheet = get_worksheet
      @notifications = @worksheet.notifications(:all)
      respond_to do |format|
        format.js { render partial: 'workshop/worksheet_xbox' }
      end
    rescue Exception => e
      respond_to do |format|
        @error = e.message+"\n"+e.backtrace.join("\n")
        format.html { render partial: 'layouts/error_html' }
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def upsync_all
    begin
      Worksheet.upsync_all
      respond_to do |format|
        apply_filter
        format.js { render partial: 'workshop/close_worksheet_js' }
      end
    rescue Exception => e
      @error = e.message+"\n\n#{e.backtrace}"
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def set_hours
    begin
      p = params.require(:worksheet).permit(:id,:hours)
      Worksheet.find(p[:id]).update(:hours => p[:hours].to_f)
      apply_filter
    rescue Exception => e
      @error = e.message
    end
    respond_to do |format|
      if @error.nil?
        format.js { render :js, :partial => 'worksheets/index_js' }
      else
        format.js { render :js, :partial => 'layouts/error' }
      end
    end
  end

  def filter
    begin
      apply_filter
    rescue Exception => e
      @error = e.message
    end
    respond_to do |format|
      if @error.nil?
        format.js { render :js, :partial => 'worksheets/index_js' }
      else
        format.js { render :js, :partial => 'layouts/error' }
      end
    end
  end

  def ow_filter
    begin
      apply_ow_filter
    rescue Exception => e
      @error = e.message
    end
    respond_to do |format|
      if @error.nil?
        format.js { render :js, :partial => 'worksheets/index_other_workshops_js' }
      else
        format.js { render :js, :partial => 'layouts/error' }
      end
    end
  end

  def toggle_closure
    begin
      ws = Worksheet.find(params.require(:worksheet).permit(:id)[:id].to_i)

      apply_filter
      ws.toggle_closure
      # if @open_worksheets_filter
      #   @orders = OutputOrder.open_worksheets_filter #.paginate(:page => params[:page], :per_page => 30)
      # else
      #   @orders = OutputOrder.all #.paginate(:page => params[:page], :per_page => 30)
      # end
      # if @search.nil? or @search == ''
      #   @orders = @orders.order(:processed => :asc, :created_at => :desc) #.paginate(:page => params[:page], :per_page => 30)
      # else
      #   @orders = @orders.findByRecipient(@search) #.paginate(:page => params[:page], :per_page => 30)
      # end
    rescue Exception => e
      @error = e.message
    end
    respond_to do |format|
      if @error.nil?
        format.js { render :js, :partial => 'worksheets/index_js' }
      else
        format.js { render :js, :partial => 'layouts/error' }
      end
    end
  end

  def change_km
    begin
      # Get params
      p = params.require(:worksheet).permit(:id,:km)

      # Update worksheet
      ws = Worksheet.find(p[:id])
      ws.update(mileage: p[:km])

      # Update vehicle
      ws.vehicle.update(mileage: p[:km])

      # Write pdf
      File.open(ws.get_pdf_path,'w').write(ws.sheet)

      # Render view
      # apply_filter
      # respond_to do |format|
      #   format.js { render :js, :partial => 'worksheets/index_js' }
      # end
    rescue Exception => e
      @error = e.message+"\n\n"+e.backtrace.join("\n")
      respond_to do |format|
        format.js { render :js, :partial => 'layouts/error' }
      end
    end
  end

  def print_pdf
    ws = Worksheet.find(params.require(:id))
    respond_to do |format|
      format.pdf do
        pdf = ws.print
        send_data pdf.render, filename:
        "lista_odl_nr_#{ws.number}.pdf",
        type: "application/pdf"
      end
    end
  end

  def get_pdf
    ws = Worksheet.find(params.require(:id))
    begin
      respond_to do |format|
        format.pdf do
          pdf = ws.get_pdf
          send_data pdf.read, filename: File.basename(pdf.path),
          type: "application/pdf"
        end
      end
    rescue
    end
  end

  private

  def get_worksheet
    Worksheet.find_by(code: "EWC*#{params.require('protocol')[/\d*/]}")
  end

  def search_params

    if params[:search].nil?
      @search = {:opened => true, :closed => false, :plate => nil, :number => nil, :date_since => (Date.today - 2.months), :date_to => Date.today, :mechanic => nil, :workshop => nil, :date_select => 'DataIntervento'}
    else
      if params[:search].is_a? String
        @search = JSON.parse(params.require(:search),:symbolize_names => true)
      else
        @search = params.require(:search).permit(:opened,:closed,:plate,:number,:date_since,:date_to,:mechanic,:workshop,:date_select)
      end
      if params[:search]['date_select'].nil? || params[:search]['date_select'] == ''
        @search[:date_select] = 'DataIntervento'
      end

      if params[:search]['opened'].nil?
        @search[:opened] = false
      else
        @search[:opened] = true
      end
      if params[:search]['closed'].nil?
        @search[:closed] = false
      else
        @search[:closed] = true
      end
    end

    if(params['commit'] == 'Aggiorna')
      upsync_all
    end
  end

  # internal workshop filter
  def apply_filter

    filter = []
    if @search[:opened] and @search[:closed]
      # filter << ''
    elsif @search[:opened] and !@search[:closed]
      filter << 'closingDate is null'
    elsif !@search[:opened] and @search[:closed]
      filter << 'closingDate is not null'
    end
    unless @search[:plate].nil? or @search[:plate] == ''
      filter << "vehicle_id in (select vehicle_id from vehicle_informations where information like '%#{@search[:plate].tr('. *-','')}%' and vehicle_information_type_id = (select id from vehicle_information_types where name = 'Targa'))"
    end
    unless @search[:number].nil? or @search[:number] == ''
      Worksheet.find_or_create_by_code(@search[:number])
      filter << "code like '%#{@search[:number]}%'"
    end
    unless @search[:date_since].nil? or @search[:date_since] == ''
      filter << "opening_date >= '#{@search[:date_since]}'"
    end
    unless @search[:date_to].nil? or @search[:date_to] == ''
      filter << "opening_date <= '#{@search[:date_to]}'"
    end
    @worksheets = Worksheet.where(filter.join(' and ')).order(:code => :asc)

    unless(params['list'].nil?)
      @search_list = params.require('list')['search']
      # @opened_list = params.require('list')['opened'] == 'on' ? true : false
    end
  end

  # Other workshops filter
  def apply_ow_filter

    # Build filter
    filter = []

    if @search[:opened] and !@search[:closed]
      filter << "(FlagSchedaChiusa like 'false' or FlagSchedaChiusa is null)"
    elsif !@search[:opened] and @search[:closed]
      filter << "FlagSchedaChiusa like 'true'"
    end
    unless @search[:plate].nil? or @search[:plate] == ''
      mrs = MssqlReference.find_by_plate(@search[:plate],false)
      filter << "Autoodl.CodiceAutomezzo in (#{mrs.map{|v| v.remote_object_id }.join(',')})" unless mrs.empty?
    end
    unless @search[:number].nil? or @search[:number] == ''
      filter << "Protocollo = #{@search[:number]}"
    end
    unless @search[:workshop].nil? or @search[:workshop] == ''
      filter << "CodiceAnagrafico = '#{@search[:workshop]}'"
    end
    unless @search[:date_since].nil? or @search[:date_since] == ''
      filter << "#{@search[:date_select]} >= '#{@search[:date_since]}'"
    end
    unless @search[:date_to].nil? or @search[:date_to] == ''
      filter << "#{@search[:date_select]} <= '#{@search[:date_to]}'"
    end
    filter << "CodiceAnagrafico != 'OFF00001' and CodiceAnagrafico != 'OFF00047'"

    # Query db
    @worksheets = EurowinController::get_filtered_odl(filter.join(' and ')+" order by #{@search[:date_select]} desc")

    unless(params['list'].nil?)
      @search_list = params.require('list')['search']
      # @opened_list = params.require('list')['opened'] == 'on' ? true : false
    end
  end

  def set_hours_params
    params.require(:worksheet).permit(:id,:hours)
  end

end
