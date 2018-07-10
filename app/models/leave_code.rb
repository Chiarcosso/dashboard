class LeaveCode < ApplicationRecord

  has_many :granted_leaves

  def self.upsync_all

    #check existign codes
    MssqlReference.query({table: 'codici_permessi'},'chiarcosso_test').each do |lc|
      LeaveCode.find_by(code: lc['codice'])
      if LeaveCode.find_by(code: lc['codice']).nil?
        LeaveCode.create(code: lc['codice'], afterhours: lc['straordinario'] == 'Straord.')
      end
    end
  end
end
