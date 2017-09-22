class MdcUser < ApplicationRecord
  resourcify

  belongs_to :assigned_to_person, class_name: 'Person'
  belongs_to :assigned_to_company, class_name: 'Company'

  def holder
    self.assigned_to_person.nil?? self.assigned_to_company : self.assigned_to_person
  end

  def self.find_by_holder string
    holder = Person.find_by_complete_name_inv(string) || Person.find_by_complete_name(string) || Company.find_by_name(string)
    if holder.class == Person
      MdcUser.where(:assigned_to_person => holder).first
    elsif holder.class == Company
      MdcUser.where(:assigned_to_company => holder).first
    end
  end
end
