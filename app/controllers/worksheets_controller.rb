class WorksheetsController < ApplicationController

  before_action :search_params

  def index
    apply_filter
    render 'workshop/index'
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

  private

  def search_params
    if params[:search].nil?
      @search = {:opened => true, :closed => false, :plate => nil, :number => nil, :date_since => nil, :date_to => nil, :mechanic => nil}
    else
      if params[:search].is_a? String
        @search = JSON.parse(params.require(:search))
      else
        @search = params.require(:search).permit(:opened,:closed,:plate,:number,:date_since,:date_to,:mechanic)
      end
    end
  end

  def apply_filter
    filter = []
    if @search[:opened] and @search[:closed]
      filter << ''
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
      filter << "closingDate >= '#{@search[:date_since]}'"
    end
    unless @search[:date_to].nil? or @search[:date_to] == ''
      filter << "closingDate <= '#{@search[:date_to]}'"
    end
    @worksheets = Worksheet.where(filter.join(' and ')).order(:code => :asc)

  end

  def set_hours_params
    params.require(:worksheet).permit(:id,:hours)
  end

end
