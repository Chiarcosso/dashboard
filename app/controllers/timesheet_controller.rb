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
        @error = "Operazione non concessa, l'utente non possiede il ruolo per questa modifica."
        raise @error
      end

      respond_to do |format|
        format.js { render partial: 'timesheets/index_js' }
      end
    rescue Exception => e
      respond_to do |format|
        @error = e.message+"\n"+e.backtrace.join("\n") if @error.nil?
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
    begin

      if (current_user.has_role?(:admin) || current_user.has_role?('amministratore officina'))
        # Get strong params
        from = params.require('from')
        ids = params.require('ids')

        # Loop through the timesheets
        ids.each do |ts|

          # Update the right approval
          case from
          when 'chief'
            TimesheetRecord.find(ts.to_i).update(chief_approval: Time.now)
          when 'hr'
            TimesheetRecord.find(ts.to_i).update(hr_approval: Time.now)
          end

        end

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

  def pdf

    unless current_user.has_role?('amministratore officina') || current_user.has_role?(:admin) || current_user.has_role?('presenze e orari') || current_user.has_role?('visione ore officina')
      return nil
    end

    pdf = Prawn::Document.new

    from = Date.strptime(params.require(:from),"%Y-%m-%d")
    to = Date.strptime(params.require(:to),"%Y-%m-%d")

    # Eventually switch dates
    if to < from
      tmp = from
      from = to
      to = tmp
    end

    # Single person or all mechanics
    if params['person'].nil? || params['person'] == ''
      # people = Person.workshop_action(from,to).order(:surname => :asc).to_a
      people = Person.mechanics.order(:surname => :asc).to_a
    else
      people = [Person.find(params['person'].to_i)]
    end

    if current_user.has_role?('amministratore officina') || current_user.has_role?(:admin) || current_user.has_role?('presenze e orari') || current_user.has_role?('visione ore officina')
      # Single person or all mechanics
      if params['person'].nil? || params['person'] == ''
        people = Person.workshop_action(from,to).order(:surname => :asc).to_a
        # people = Person.mechanics.order(:surname => :asc).to_a
      else
        people = [Person.find(params['person'].to_i)]
      end
    else
      people = [current_user.person]
    end

    # Loop over people
    people.each do |person|
      pdf.text "#{person.list_name}",size: 26, font_style: :bold, align: :center
      date = from

      # Loop over dates
      while date <= to do

        pdf.text "Operazioni del #{date.strftime("%d/%m/%Y")}",size: 20, font_style: :bold
        timesheets = TimesheetRecord.where(person: person)
            .where("timesheet_records.start between '#{date.strftime("%Y-%m-%d")} 00:00:00' and '#{date.strftime("%Y-%m-%d")} 23:59:59'")
            .order(:start => :asc)

        if timesheets.count < 1
          pdf.text "non ci sono operazioni di #{person.list_name}",size: 15, font_style: :bold
        end
           # - if t.minutes.nil?
           #   %br
           #   %b{style: 'color: #f00'}= "Errore: tempo non presente -> #{t.time_label}"
           # - if t.minutes.to_i > (24 * 60)
           #   %br
           #   %b{style: 'color: #f00'}= "Errore: operazione durata più di 24 ore -> #{t.time_label}"
           total = 0
        timesheets.each_with_index do |t,i|


          pdf.move_down 10
          total += t.minutes.to_i
          ws = t.workshop_operation.worksheet unless t.workshop_operation.nil?
          odl = "ODL nr. #{ws.number} - #{ws.vehicle.plate}" unless ws.nil?
          notification = t.workshop_operation.ew_notification unless t.workshop_operation.nil?
          odl += " - #{notification['DescrizioneSegnalazione']}" unless notification.nil?
          # odl = odl[0..51]+".." unless odl.nil? || odl.length < 52
          # odl = "#{odl.length} #{odl}" unless odl.nil?
          description = "#{t.id} - #{t.description} #{t.workshop_operation_id.nil? ? '' : "(#{t.workshop_operation_id})"}"
          minutes = "#{t.minutes} min."
          fromto = "#{t.start.strftime("%d/%m/%Y %H:%M:%S")} \n#{t.stop.nil? ? 'Non conclusa' : t.stop.strftime("%d/%m/%Y %H:%M:%S")}"

          pdf.table [
            [
              # pdf.make_cell(content: (i+1).to_s,size: 26, font_style: :bold,height: 27, align: :center, valign: :center),
              pdf.make_table(
                [
                  [
                    pdf.make_cell(content: odl.nil? ? '' : odl.tr("\n",' '),size: 17, font_style: :bold,height: 27,borders: [],width: 540)
                  ],
                  [pdf.make_table([[
                    pdf.make_cell(content: description,size: 13,borders: [],width: 330),
                    pdf.make_cell(content: minutes,size: 13,borders: [],width: 70),
                    pdf.make_cell(content: fromto,size: 13,borders: [],width: 140)
                  ]])]
                ],width: 540
              )
            ]
          ],

          :position => :center,
          :column_widths => { 0 => 540},
          # :align => { 0 => :right, 1 => :left, 2 => :right, 3 => :left},
          :row_colors => ["FFFFFF"]

        end

        pdf.move_down 20

        # if total > 0

          # Summary
          hrs = (total / 60).floor
          mins = total % 60

          pr = PresenceRecord.actual_day_time_label(date, person)
          if pr.nil?
            pr_text = "Non sono presenti timbrature"
          else
            pr_text= "#{pr}"
          end

          ws = WorkingSchedule.get_schedule(date,person)
          if ws.nil?
            ws_text = "Non è stato concordato un orario per questa giornata."
          else
            ws_text = ws.expected_hours_label
          end

          pdf.text "Totale: #{hrs.to_s.rjust(2,'0')}:#{mins.to_s.rjust(2,'0')}", size: 15, font_style: :bold
          pdf.text "Totale timbrature: #{pr_text}", size: 15, font_style: :normal
          pdf.text "Totale concordato: #{ws_text}", size: 15, font_style: :normal

          pdf.move_down 20

        # end
        date += 1.days
      end



      pdf.bounding_box([pdf.bounds.right - 50,pdf.bounds.bottom], :width => 60, :height => 20) do
      	count = pdf.page_count
      	pdf.text "Pagina #{count}"
      end

    end
    respond_to do |format|
      format.pdf do
        pdf = pdf
        send_data pdf.render, filename:
        "officina#{people.count == 1 ? "_#{people[0].surname}" : ''}_#{from.strftime("%Y_%m_%d")}#{(from != to) ? "_"+to.strftime("%Y_%m_%d") : ''}.pdf",
        type: "application/pdf"
      end
    end
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
    if current_user.has_role?('amministratore officina') || current_user.has_role?(:admin) || current_user.has_role?('presenze e orari') || current_user.has_role?('visione ore officina')
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
    Person.present_mechanics(@date).each do |p|
      @timesheets[p.list_name] = Array.new if @timesheets[p.list_name].nil?
    end
  end
end
