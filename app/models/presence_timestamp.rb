class PresenceTimestamp < ApplicationRecord
  belongs_to :badge
  has_one :starting_record, class_name: 'PresenceRecord', foreign_key: :start_ts_id
  has_one :ending_record, class_name: 'PresenceRecord', foreign_key: :end_ts_id

  scope :real_timestamps, -> { where(added: false, deleted: false) }
  scope :date, ->(date) {where("year(time) = #{date.strftime("%Y")} and month(time) = #{date.strftime("%-m")} and day(time) = #{date.strftime("%e")}")}
  scope :badges, ->(badges) {where("badge_id in (select #{badges.map{|b| b.id}.join(',')})")}
  belongs_to :sensor

  enum months: ['Gennaio','Febbraio','Marzo','Aprile','Maggio','Giugno','Luglio','Agosto','Settembre','Ottobre','Novembre','Dicembre']

  def self.years
    years = Array.new

    for i in 2015..Date.today.strftime("%Y").to_i
      years << i
    end
    years.reverse
  end

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
