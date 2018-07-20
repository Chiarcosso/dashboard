class LeaveCode < ApplicationRecord

  has_many :granted_leaves



  def self.upsync_all

    #check existign codes
    MssqlReference.query({table: 'codici_permessi'},'chiarcosso_test').each do |lc|
      llc = LeaveCode.find_by(code: lc['codice'])
      if llc.nil?
        LeaveCode.create(code: lc['codice'], afterhours: lc['straordinario'] == 'Straord.', description: lc['descrizione'].capitalize)
      else
        llc.update(code: lc['codice'], afterhours: lc['straordinario'] == 'Straord.', description: lc['descrizione'].capitalize)
      end
    end
  end
end
