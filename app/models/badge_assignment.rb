class BadgeAssignment < ApplicationRecord

  belongs_to :badge
  belongs_to :person

  def self.find_or_create(data)

    #data -> badge: Badge
    #        person: Person
    #        from: Date
    #        to: Date

    #attempt to find
    badge_assignment = BadgeAssignment.find_by(data)

    #if not found create or else update
    if badge_assignment.nil?
      badge_assignment = BadgeAssignment.create(data)
    else
      badge_assignment.update(data)
    end

    badge_assignment
  end

end
