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

  def assign_default_role
    self.add_role(:base) if self.roles.blank?
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
