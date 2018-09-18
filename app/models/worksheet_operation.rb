class WorksheetOperation < ApplicationRecord
  belongs_to :worksheet
  belongs_to :workshop_operation
  belongs_to :person

  
end
