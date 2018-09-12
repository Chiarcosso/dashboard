class WorksheetsController < ApplicationController

  before_action :search_params

  def index
    begin
      apply_filter
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
        format.js { render :js, :partial => 'workshop/worksheet_total_list_js' }
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
        format.js { render :js, :partial => 'workshop/worksheet_total_list_js' }
      else
        format.js { render :js, :partial => 'layouts/error' }
      end
    end
  end

  def toggle_closure
    begin
      ws = Worksheet.find(params.require(:worksheet).permit(:id)[:id].to_i)

      ws.toggle_closure
      apply_filter
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
        format.js { render :js, :partial => 'workshop/worksheet_total_list_js' }
      else
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
      @search = {:opened => true, :closed => false, :plate => nil, :number => nil, :date_since => (Date.today - 180), :date_to => Date.today, :mechanic => nil}
    else
      if params[:search].is_a? String
        @search = JSON.parse(params.require(:search))
      else
        @search = params.require(:search).permit(:opened,:closed,:plate,:number,:date_since,:date_to,:mechanic)
      end
    end

    if(params['commit'] == 'Aggiorna')
      upsync_all
    end
  end

  def apply_filter
    filter = []

    if @search.with_indifferent_access[:opened] and @search.with_indifferent_access[:closed]
      # filter << ''
    elsif @search.with_indifferent_access[:opened] and !@search.with_indifferent_access[:closed]
      filter << 'closingDate is null'
    elsif !@search.with_indifferent_access[:opened] and @search.with_indifferent_access[:closed]
      filter << 'closingDate is not null'
    end
    unless @search.with_indifferent_access[:plate].nil? or @search.with_indifferent_access[:plate] == ''
      filter << "vehicle_id in (select vehicle_id from vehicle_informations where information like '%#{@search.with_indifferent_access[:plate].tr('. *-','')}%' and vehicle_information_type_id = (select id from vehicle_information_types where name = 'Targa'))"
    end
    unless @search.with_indifferent_access[:number].nil? or @search.with_indifferent_access[:number] == ''
      Worksheet.find_or_create_by_code(@search.with_indifferent_access[:number])
      filter << "code like '%#{@search.with_indifferent_access[:number]}%'"
    end
    unless @search.with_indifferent_access[:date_since].nil? or @search.with_indifferent_access[:date_since] == ''
      filter << "opening_date >= '#{@search.with_indifferent_access[:date_since]}'"
    end
    unless @search.with_indifferent_access[:date_to].nil? or @search.with_indifferent_access[:date_to] == ''
      filter << "opening_date <= '#{@search.with_indifferent_access[:date_to]}'"
    end
    @worksheets = Worksheet.where(filter.join(' and ')).limit(100).order(:code => :asc)

    unless(params['list'].nil?)
      @search_list = params.require('list')['search']
      # @opened_list = params.require('list')['opened'] == 'on' ? true : false
    end
  end

  def set_hours_params
    params.require(:worksheet).permit(:id,:hours)
  end

end
