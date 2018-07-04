class WorkingSchedule < ApplicationRecord
  belongs_to :person

  enum weekdays: ['Lunedi', 'Martedi', 'Mercoledi', 'Giovedi', 'Venerdi', 'Sabato']

end
