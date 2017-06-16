class Person < ApplicationRecord
  resourcify

  has_many :relations, class_name: 'CompanyPerson', :dependent => :delete_all
  has_many :companies, through: :relations
  has_many :company_relations, through: :relations

  scope :order_alpha, -> { order(:surname) }
  scope :filter, ->(name) { where('name like ? or surname like ?', "%#{name}%", "%#{name}%").order(:surname) }
  scope :mdc, -> { where("mdc_user is not null and mdc_user != ''") }
  scope :order_mdc_user, -> { order(:mdc_user)}
  # scope :company, ->(name) { joins(:companies).where('company.name like ?',"%#{name}%") }

  def self.find_by_mdc_user(user)
    Person.mdc.where(:mdc_user => user).first
  end

  def complete_name
    self.name+' '+self.surname
  end

  def list_name
    self.surname+' '+self.name
  end
end
