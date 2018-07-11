class Badge < ApplicationRecord

  has_many :badge_assignments
  has_many :peole, through: :badge_assignments

  def current_holder
    Person.find_by_sql("select * from People where id = (select person_id from badge_assignments where to is null and badge_id = #{self.id} order by from desc limit 1) limit 1")
  end

  def self.find_or_create(badge)

    b = Badge.find_by(code: badge.to_s)
    ref = MssqlReference.query({table: 'badge', where: {badge: badge.to_s}},'chiarcosso_test')
    if b.nil?
      b = Badge.create(code: badge)
    end

    ref.each do |ba|

      case ba['tabella']
      when 'Dipendenti' then
        table = 'Autisti'
      when 'Esterni' then
        table = 'Clienti'
      end

      person = Person.find_or_create(mssql_id: ba['persona_id'], table: table)

      BadgeAssignment.find_or_create({badge: b, person: person, from: ba['da'], to: ba['a']})

    end
    b
  end

  def self.upsync_all
    MssqlReference.query({table: 'badge', where: {'tabella': 'Dipendenti'}},'chiarcosso_test').each do |b|
      Badge.find_or_create(b['badge'])
    end
  end
end
