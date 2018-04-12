class CarwashUsage < ApplicationRecord
  belongs_to :person
  belongs_to :carwash_special_code
  belongs_to :vehicle_1, class_name: "Vehicle"
  belongs_to :vehicle_2, class_name: "Vehicle"

  scope :opened, -> { where(:ending_time => nil) }
  scope :closed, -> { where('ending_time is not null') }
  scope :lastmonth, -> { where('ending_time > ?', DateTime.now - 30.days) }
  scope :yesterday, -> { where('ending_time > ?', DateTime.now - 1.days) }

  def self.generate_session
    id = SecureRandom.hex(10)
    while (!CarwashUsage.find_by(:session_id => id).nil?) do
      id = SecureRandom.hex(10)
    end
    id
  end
end
