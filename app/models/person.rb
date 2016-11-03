class Person < ApplicationRecord
  resourcify

  def completeName
    self.name+' '+self.surname
  end
end
