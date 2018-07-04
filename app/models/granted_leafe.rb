class GrantedLeafe < ApplicationRecord
  belongs_to :leave_code
  belongs_to :person
end
