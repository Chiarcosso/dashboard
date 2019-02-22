class Badge < ApplicationRecord

  has_many :badge_assignments
  has_many :peole, through: :badge_assignments

  scope :assigned, -> { where("id in (select badge_id from badge_assignments where badge_assignments.to = '1900-01-01')") }
  scope :unassigned, -> { where("id not in (select badge_id from badge_assignments where badge_assignments.to = '1900-01-01') "\
                          "or id in (select badge_id from badge_assignments where badge_assignments.to != '1900-01-01' and badge_assignments.to < '#{Date.today.strftime('%Y-%m-%d')}')") }

  def assigned?(data)
    # if data.nil?
    #   self.badge_asssignments.reject{ |ba| ba.to == Date.strptime("1900-01-01","%Y-%m-%d")}.count > 0
    # else
    #   if data[:from].nil?
    #     BadgeAssigments.where("badge_assignments.to < #{data[:from]}")
    #   else
    #     BadgeAssignments.where(badge: self).where("(badge_assignments.from between '#{data[:from].strftime('%Y-%m-%d')}' and '#{data[:to].strftime('%Y-%m-%d')}') "\
    #               "or (badge_assignments.to between '#{data[:from].strftime('%Y-%m-%d')}' and '#{data[:to].strftime('%Y-%m-%d')}' "\
    #               "or ('#{data[:from].strftime('%Y-%m-%d')}' between badge_assignments.from and badge_assignments.to").count > 0
    #   end
    # end

    self.holders(data).count > 0
  end

  def holders(data = {from: Time.today, to: nil, exclude: nil})

    if data[:to].nil?
      # p = Person.find_by_sql("select * from people where id in ("\
      # "select person_id from badge_assignments.to > '#{data[:from].strftime('%Y-%m-%d')}' #{data[:exclude].nil?? '' : "and id != #{data[:exclude].id}"}"\
      # ")")
      p = Person.find_by_sql(<<-QRY
          select * from people where id in (
            select person_id from badge_assignments
            where badge_id = #{self.id} and
            ((badge_assignments.to is null or badge_assignments.to = '1900-01-01')
            or badge_assignments.to >= '#{data[:from].strftime('%Y-%m-%d')}')
          )
        QRY
      )
      # BadgeAssigments.where("badge_assignments.to > '#{data[:from].strftime('%Y-%m-%d')}' #{data[:exclude].nil?? '' : "and id != #{data[:exclude].id}"}")
    else
      # p = Person.find_by_sql(<<-QRY
      #
      #   select * from people where id in (
      #     select person_id from badge_assignments
      #     where #{data[:exclude].nil?? '' : "id != #{data[:exclude].id} and"}
      #     (
      #       (badge_assignments.from between '#{data[:from].strftime('%Y-%m-%d')}' and '#{data[:to].strftime('%Y-%m-%d')}')
      #       or (badge_assignments.to between '#{data[:from].strftime('%Y-%m-%d')}' and '#{data[:to].strftime('%Y-%m-%d')}')
      #       or ('#{data[:from].strftime('%Y-%m-%d')}' between badge_assignments.from and badge_assignments.to)
      #     )
      #     and badge_id = #{self.id}
      #     order by badge_assignments.from desc limit 1) limit 1
      #
      #   QRY
      # )
      p = Person.find_by_sql(<<-QRY

        select * from people where id in (
          select person_id from badge_assignments
          where #{data[:exclude].nil?? '' : "id != #{data[:exclude].id} and"}
          ((
            badge_assignments.from <= '#{data[:to].strftime('%Y-%m-%d')}'
            and badge_assignments.to >= '#{data[:from].strftime('%Y-%m-%d')}'
          )
          or (
            badge_assignments.from <= '#{data[:to].strftime('%Y-%m-%d')}'
            and (badge_assignments.to is null or badge_assignments.to = '1900-01-01')
          ))
          and badge_id = #{self.id}
          order by badge_assignments.from desc
        )

        QRY
      )
    end
    return p
  end

  def current_holder
    Person.find_by_sql("select * from people where id = (select person_id from badge_assignments where (to is null or to = '1900-01-01') and badge_id = #{self.id} order by from desc limit 1) limit 1")
  end

  def day_holder(date = Date.today)
    Person.find_by_sql("select * from people where id = (select person_id from badge_assignments where (((badge_assignments.to = '1900-01-01' or badge_assignments.to is null) and '#{date.strftime("%Y-%m-%d")}' >= badge_assignments.from) or ('#{date.strftime("%Y-%m-%d")}' between badge_assignments.from and badge_assignments.to)) and badge_id = #{self.id} order by badge_assignments.from desc limit 1) limit 1").first
  end

  def self.find_or_create(badge)

    b = Badge.find_by(code: badge.to_s)
    # ref = MssqlReference.query({table: 'badge', where: {badge: badge.to_s}},'chiarcosso_test')
    if b.nil?
      b = Badge.create(code: badge)
    end

    # ref.each do |ba|
    #
    #   case ba['tabella']
    #   when 'Dipendenti' then
    #     table = 'Autisti'
    #   when 'Esterni' then
    #     table = 'Clienti'
    #   end
    #
    #   person = Person.find_or_create(mssql_id: ba['persona_id'], table: table)
    #
    #   # BadgeAssignment.find_or_create({badge: b, person: person, from: ba['da'], to: ba['a']})
    #
    # end
    b
  end

  def self.upsync_all
    MssqlReference.query({table: 'badge', where: {'tabella': 'Dipendenti'}},'chiarcosso_test').each do |b|
      Badge.find_or_create(b['badge'])
    end
  end
end
