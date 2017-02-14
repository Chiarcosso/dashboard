class Person < ApplicationRecord
  resourcify

  def complete_name
    self.name+' '+self.surname
  end
end
