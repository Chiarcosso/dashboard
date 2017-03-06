class Person < ApplicationRecord
  resourcify

  has_many :relations, class_name: 'CompanyPerson'
  # has_and_belongs_to_many :companies, through: :relations
  # has_and_belongs_to_many :company_relations, through: :relations


  def complete_name
    self.name+' '+self.surname
  end
end
