class LeaveCode < ApplicationRecord

  has_many :granted_leaves

  def self.find_or_create_by_mssql_reference(id)
    mr = MssqlReference.where(remote_object_table: 'codici_permessi', remote_object_id: id).first
    if mr.nil?
      rlc = MssqlReference.query({table: 'codici_permessi', where: {id: id}},'chiarcosso_test').first
      lc = LeaveCode.find_by(code: rlc['codice'])
      if lc.nil?
        lc = LeaveCode.create(code: lc['codice'], afterhours: lc['straordinario'] == 'Straord.', description: lc['descrizione'].capitalize)
      end
      MssqlReference.create(local_object: lc, remote_object_table: 'codici_permessi', remote_object_id: rlc['id'])
    else
      lc = mr.local_object
    end
    lc
  end

  def self.upsync_all

    #check existign codes
    MssqlReference.query({table: 'codici_permessi'},'chiarcosso_test').each do |lc|
      llc = LeaveCode.find_by(code: lc['codice'])
      if llc.nil?
        lc = LeaveCode.create(code: lc['codice'], afterhours: lc['straordinario'] == 'Straord.', description: lc['descrizione'].capitalize)
        MssqlReference.create(local_object: lc, remote_object_table: 'codici_permessi', remote_object_id: lc['id'])
      else
        llc.update(code: lc['codice'], afterhours: lc['straordinario'] == 'Straord.', description: lc['descrizione'].capitalize)
      end
    end
  end
end
