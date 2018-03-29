class VehicleCheckSession < ApplicationRecord
  belongs_to :operator
  belongs_to :worksheet

  def expected_time
    nil
  end

  def real_time
    nil
  end

end
