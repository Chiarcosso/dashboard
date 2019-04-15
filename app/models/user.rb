class User < ApplicationRecord
  resourcify
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  belongs_to :person, optional: true
  has_many :offices

  after_create :assign_default_role

  has_many :mdc_reports

  def new_mdc_reports_for_office(office)
    if office == :hr && !(self.roles.include?('mdc personale') || self.roles.include?('admin'))
      return
    elsif office == :logistcs && !(self.roles.include?('mdc traffico') || self.roles.include?('admin'))
      return
    elsif office == :maintenance && !(self.roles.include?('mdc manutenzioni') || self.roles.include?('admin'))
      return
    else
      res = MdcReport.where(managed_at: nil)
      return res.where("#{office} = 1")
    end
  end

  def assign_default_role
    self.add_role(:base) if self.roles.blank?
  end

  def mssql_code
    self.person.mssql_references.last.remote_object_id
  end

  def name
    if ! self.person.nil?
      self.person.name+' '+self.person.surname
    elsif ! self.username.nil?
      self.username
    else
      self.email
    end
  end
end
