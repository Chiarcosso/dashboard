class PresenceTimestamp < ApplicationRecord
  belongs_to :badge

  scope :real_timestamps, -> { where(added: false, deleted: false) }
  belongs_to :sensor
  
  def self.find_or_create(opts)
    #opts = badge: Badge,
          # sensor: Sensor,
          # time: Datetime
          # file: sting
          # row: int

    pts = PresenceTimestamp.find_by(badge: opts[:badge], time: opts[:time], sensor: opts[:sensor])
    pts = PresenceTimestamp.create(opts) if pts.nil?
    pts
  end
end
