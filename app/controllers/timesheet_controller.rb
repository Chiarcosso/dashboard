class TimesheetController < ApplicationController
  before_action :authenticate_user!
  before_action :get_timesheets, only: [:index]

  def index
    begin
      respond_to do |format|
        format.html { render 'timesheets/index' }
        format.js { render partial: 'timesheets/index_js' }
      end
    rescue Exception => e
      respond_to do |format|
        @error = e.message+"\n"+e.backtrace.join("\n")
        format.html { render partial: 'layouts/error_html' }
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def update
    begin
      if (current_user.has_role?(:admin) || current_user.has_role?('amministratore officina'))
        # Get strong params
        p = params.require(:timesheet).permit(:id,:minutes,:hr_approval,:chief_approval)

        # Find the timesheet record
        timesheet = TimesheetRecord.find(p[:id].to_i)

        # Transform approvals in timestamps for the record.
        # If it's missing, unset it to the instance.
        # If it's already set, remove it to avoid unsetting
        if p[:hr_approval] == 'true' && timesheet.hr_approval.nil?
          p[:hr_approval] = Time.now
        elsif p[:hr_approval].nil?
          p[:hr_approval] = nil
        else
          p.delete(:hr_approval)
        end
        if p[:chief_approval] == 'true' && timesheet.chief_approval.nil?
          p[:chief_approval] = Time.now
        elsif p[:chief_approval].nil?
          p[:chief_approval] = nil
        else
          p.delete(:chief_approval)
        end

        # Transform time in minutes
        tmp = p[:minutes].split(':')
        p[:minutes] = tmp[0].to_i * 60 + tmp[1].to_i

        # Update timesheet record
        timesheet.update(p)
        get_timesheets
      else
        raise "Operazione non concessa, l'utente non possiede il ruolo per questa modifica."
      end

      respond_to do |format|
        format.js { render partial: 'timesheets/index_js' }
      end
    rescue Exception => e
      respond_to do |format|
        @error = e.message+"\n"+e.backtrace.join("\n")
        format.html { render partial: 'layouts/error_html' }
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def timesheet_start
    begin

      # Get params
      p = params.require(:timesheet).permit(:person_id, :description)

      # Create new Timesheet record
      tr = TimesheetRecord.create(person: Person.find(p[:person_id].to_i), description: p[:description], start: Time.now)

      # Return the timesheet record id
      respond_to do |format|
        format.js { render json: tr.id }
      end
    rescue Exception => e
      @error = e.message+"\n\n#{e.backtrace}"
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def timesheet_stop
    begin

      # Get the record and update it
      tr = TimesheetRecord.find(params.require(:id).to_i)
      time = ((Time.now - tr.start) / 60).ceil
      tr.update(stop: Time.now, minutes: time)

      respond_to do |format|
        format.js { render json: tr.id }
      end
    rescue Exception => e
      @error = e.message+"\n\n#{e.backtrace}"
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def timesheet_popup
    begin
      respond_to do |format|
        format.js { render partial: 'timesheets/timesheet_popup' }
      end
    rescue Exception => e
      @error = e.message+"\n\n#{e.backtrace}"
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def massive_approval
    
  end

  private

  def get_timesheets
    # Set date
    if params[:date].nil?
      @date = Time.now - 1.days
    else
      @date = Time.strptime(params[:date],"%Y-%m-%d")
    end
    unless params[:name].nil?
      @name = params[:name]
    end
    # If the user does not have manage_timesheets role filter just his timesheet records
    if current_user.has_role?('amministratore officina') || current_user.has_role?(:admin) || current_user.has_role?('gestione orari')
      trs = TimesheetRecord.find_by_sql(<<-SQL
          select timesheet_records.*,
          (select concat(people.surname,' ',people.name) from people where people.id = timesheet_records.person_id) as name
          from timesheet_records
          where timesheet_records.start between '#{@date.strftime("%Y-%m-%d")} 00:00:00' and '#{@date.strftime("%Y-%m-%d")} 23:59:59'
          order by name asc, start desc
        SQL
      )
    else
      trs = TimesheetRecord.find_by_sql(<<-SQL
          select timesheet_records.*,
          (select concat(people.surname,' ',people.name) from people where people.id = timesheet_records.person_id) as name
          from timesheet_records
          where timesheet_records.person_id = #{current_user.person_id}
            and timesheet_records.start between '#{@date.strftime("%Y-%m-%d")} 00:00:00' and '#{@date.strftime("%Y-%m-%d")} 23:59:59'
          order by name asc, start desc
        SQL
      )
    end
    # Map timesheets to a Hash with names for keys
    @timesheets = Hash.new
    trs.each do |tr|
      @timesheets[tr[:name]] = Array.new if @timesheets[tr[:name]].nil?
      @timesheets[tr[:name]] << tr
    end
  end
end
