class CarwashUsage < ApplicationRecord
  belongs_to :person
  belongs_to :vehicle_1, class_name: "Vehicle"
  belongs_to :vehicle_2, class_name: "Vehicle"

  scope :opened, -> { where(:ending_time => nil) }
  scope :lastmonth, -> { where('ending_time > ?', DateTime.now - 30.days) }
end
