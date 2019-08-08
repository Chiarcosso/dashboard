class MdcUser < ApplicationRecord
  resourcify

  belongs_to :assigned_to_person, class_name: 'Person'
  belongs_to :assigned_to_company, class_name: 'Company'

  scope :assigned, -> { where("assigned_to_person_id is not null or assigned_to_company_id is not null") }

  def holder
    self.assigned_to_person.nil?? self.assigned_to_company : self.assigned_to_person
  end

  def mdc_user
    self.user
  end

  def complete_name
    # if self.assigned_to_person.nil?
    #   self.assigned_to_company.complete_name
    # elsif self.assigned_to_company.nil?
    #   self.assigned_to_person.complete_name
    # else
    #   "#{self.assigned_to_person.complete_name} (#{self.assigned_to_company.complete_name})"
    # end
    "#{self.holder.list_name} (#{self.user.upcase})"
  end

  def self.find_by_holder string

    # Find at least a holder
    holder = Person.find_by_complete_name_inv(string) || Person.find_by_complete_name(string) || Company.find_by_name(string)

    # Find people that respond to that name, to avoid errors
    holders = Person.where("lower(concat_ws(' ',surname,name)) = ? or lower(concat_ws(' ',name,surname)) = ?", string, string)

    if holder.class == Person && holders.count > 0
      MdcUser.where("mdc_users.assigned_to_person_id in (#{holders.map{|p| p.id}.join(',')})").first
    elsif holder.class == Company
      MdcUser.where(:assigned_to_company => holder).first
    end
  end
end
