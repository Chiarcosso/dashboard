class WorkingSchedule < ApplicationRecord
  belongs_to :person

  enum weekdays: ['Lunedi', 'Martedi', 'Mercoledi', 'Giovedi', 'Venerdi', 'Sabato', 'Domenica']

  def self.get_schedule(date,person)
    weekday = date.strftime('%u').to_i-1
    working_schedule = WorkingSchedule.find_by(person: person, weekday: weekday)
  end

  def duration_agreement
    self.agreement_to.to_i - self.agreement_from.to_i - self.break * 60
  end

  def duration_agreement_label
    "#{self.duration_agreement/3600}:#{((self.duration_agreement%3600)/60).to_s.rjust(2,'0')}"
  end

  def duration_contract
    self.contract_to.to_i - self.contract_from.to_i - self.break * 60
  end

  def duration_contract_label
    "#{self.duration_contract/3600}:#{((self.duration_contract%3600)/60).to_s.rjust(2,'0')}"
  end

  def contract_duration
    (self.contract_to - self.contract_from).to_i - self.break * 60
  end

  def transform_to_date(date,time = :agreement_from)
    case time
    when :agreement_from then
      selected_time = self.agreement_from
    when :agreement_to then
      selected_time = self.agreement_to
    when :contract_from then
      selected_time = self.contract_from
    when :contract_to then
      selected_time = self.contract_to
    end
    DateTime.strptime("#{date.strftime("%Y-%m-%d")} #{selected_time.strftime("%H:%M")} UTC","%Y-%m-%d %H:%M %Z")
  end

  def self.upsync_all
    #for every found schedule transpose it in dashboard
    MssqlReference.query({table: 'orari_personale'},'chiarcosso_test').each do |ws|

      #find the person
      person = Person.find_or_create(mssql_id: ws['persona_id'], table: 'Autisti')

      #find out what days the schedule applies
      wd = Array.new

      if(ws['lunedi'] == 'x')
        wd << WorkingSchedule.weekdays['Lunedi'].to_i
      end
      if(ws['martedi'] == 'x')
        wd << WorkingSchedule.weekdays['Martedi'].to_i
      end
      if(ws['mercoledi'] == 'x')
        wd << WorkingSchedule.weekdays['Mercoledi'].to_i
      end
      if(ws['giovedi'] == 'x')
        wd << WorkingSchedule.weekdays['Giovedi'].to_i
      end
      if(ws['venerdi'] == 'x')
        wd << WorkingSchedule.weekdays['Venerdi'].to_i
      end
      if(ws['sabato1'] == 'x')
        wd << WorkingSchedule.weekdays['Sabato'].to_i
      end
      if(ws['sabato2'] == 'x')
        wd << WorkingSchedule.weekdays['Sabato'].to_i
      end
      if(ws['sabato3'] == 'x')
        wd << WorkingSchedule.weekdays['Sabato'].to_i
      end
      if(ws['sabato4'] == 'x')
        wd << WorkingSchedule.weekdays['Sabato'].to_i
      end

      #find out the times
      starting_time = ws['inizio1']-1.hour
      ending_time = (ws['fine2'] == Time.new('1900-01-01 00:00:00 +0100') ? ws['fine1']-1.hour : ws['fine2']-1.hour)
      if ws['inizio2'] == Time.new('1900-01-01 00:00:00 +0100')
        breaktime = 0
      else
        breaktime = ((ws['inizio2']-ws['fine1'])/60).to_i
      end

      #create every missing daily schedule
      wd.each do |d|
        schedule = WorkingSchedule.find_by(weekday: d, person: person)
        if schedule.nil?
          WorkingSchedule.create(person: person, weekday: d, agreement_from: starting_time, contract_from: starting_time, agreement_to: ending_time, contract_to: ending_time, break: breaktime)
        end
      end
    end
  end

end
