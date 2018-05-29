class PrepaidCard < ApplicationRecord
  belongs_to :person

  scope :valid,-> {where(dismissed: false).where("expiring_date >= '#{Date.today.strftime('%y-%m-%d')}'")}
  scope :filter, ->(search) { joins('left join people on people.id = prepaid_cards.person_id').where("serial like ? or concat(people.name,' ',people.surname) like ? or concat(people.surname,' ',people.name) like ?","%#{search.to_s.tr('*','%')}%","%#{search.to_s.tr('*','%')}%","%#{search.to_s.tr('*','%')}%") }
  scope :person_alpha_order, -> { joins('left join people on people.id = prepaid_cards.person_id').order('people.surname asc, people.name asc') }
  scope :active, ->(active) { active.nil?? where('1') : where(:dismissed => !active) }

  def is_valid?
    !self.dismissed && self.expiring_date >= Date.today
  end

  def expiration_style
    if self.expiring_date == Date.today
      'background-color: #ff9;'
    elsif self.expiring_date < Date.today
      'background-color: #f99;'
    end
  end
end
