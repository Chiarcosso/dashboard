class WorksheetOperation < ApplicationRecord
  belongs_to :worksheet
  belongs_to :workshop_operation
  belongs_to :person

  def siblings
    WorksheetOperation.where(myofficina_reference: self.myofficina_reference)
  end
end
