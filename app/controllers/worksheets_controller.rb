class WorksheetsController < ApplicationController

  before_action :search_params, only: [:filter,:index]

  def index
    apply_filter
    render 'workshop/index'
  end

  def set_hours
    Worksheet.find(set_hours_params[:id]).update(:hours => set_hours_params[:hours])
  end

  def filter
    begin
      apply_filter
    rescue Exception => e
      @error = e.message
    end
    respond_to do |format|
      if @error.nil?
        format.js { render :js, :partial => 'worksheets/worksheet_total_list_js' }
      else
        format.js { render :js, :partial => 'layout/error' }
      end
    end
  end

  def toggle_closure
    ws = Worksheet.find(params[:id].to_i)
    # OutputOrder.where("destination_type = 'Worksheet' and destination_id = ?",ws.id).each do |oo|
    #   oo.update(:processed => !ws.opened?)
    # end
    ws.toggle_closure
    search_params
    if @open_worksheets_filter
      @orders = OutputOrder.open_worksheets_filter #.paginate(:page => params[:page], :per_page => 30)
    else
      @orders = OutputOrder.all #.paginate(:page => params[:page], :per_page => 30)
    end
    if @search.nil? or @search == ''
      @orders = @orders.order(:processed => :asc, :created_at => :desc) #.paginate(:page => params[:page], :per_page => 30)
    else
      @orders = @orders.findByRecipient(@search) #.paginate(:page => params[:page], :per_page => 30)
    end

    respond_to do |format|
      format.js { render :js, :partial => 'orders/edit_output_orders' }
    end
  end

  private

  def search_params
    if params[:search].nil?
      @search = {:opened => true, :closed => false, :plate => nil, :number => nil, :date_since => nil, :date_to => nil, :mechanic => nil}
    else
      @search = params.require(search).permit(:opened,:closed,:plate,:number,:date_since,:date_to,:mechanic)
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
      filter << "vehicle_id in (select vehicle_id from vehicle_informations where information like '%#{@search[:plate].tr('. *-','')}%' vehicle_information_type_id = (select id from vehicle_information_types where name = 'Targa'))"
    end
    unless @search[:date_since].nil? or @search[:date_since] == ''
      filter << "closingDate >= #{@search[:date_since]}"
    end
    unless @search[:date_to].nil? or @search[:date_to] == ''
      filter << "closingDate <= #{@search[:date_to]}"
    end
    @worksheets = Worksheet.where(filter.join(' and '))
  end

  def set_hours_params
    params.require(:worksheet).permit(:id,:hours)
  end

end
