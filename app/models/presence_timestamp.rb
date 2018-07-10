class PresenceTimestamp < ApplicationRecord
  belongs_to :badge

  scope :real_timestamps, -> { where(added: false, deleted: false) }
  
end
