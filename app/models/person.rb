class Person < ApplicationRecord
  resourcify

  has_many :relations, class_name: 'CompanyPerson', :dependent => :delete_all
  has_many :companies, through: :relations
  has_many :company_relations, through: :relations

  has_many :prepaid_cards
  has_many :badge_assignations
  has_many :badges, through: :badge_assignations
  has_many :presence_timestamps, through: :badges
  has_many :working_schedules


  has_one :carwash_driver_code, :dependent => :destroy
  has_many :mssql_references, as: :local_object
  has_many :vehicle_properties, as: :owner

  scope :order_alpha, -> { order(:name).order(:surname) }
  scope :order_alpha_surname, -> { order(:surname).order(:name) }
  # scope :find_by_complete_name,->(name) { where("lower(concat_ws(' ',surname,name)) = ?", name) }
  # scope :find_by_complete_name_inv,->(name) { where("lower(concat_ws(' ',name,surname)) = ?", name) }
  scope :filter, ->(name) { where("name like ? or surname like ? or mdc_user like ? or ('mdc' like ? and mdc_user is not null and mdc_user != '')", "%#{name}%", "%#{name}%", "%#{name}%", "%#{name}%").order(:surname) }
  scope :mdc, -> { where("mdc_user is not null and mdc_user != ''") }
  scope :order_mdc_user, -> { order(:mdc_user)}
  scope :employees, -> { joins(:companies).where("company_id = #{Company.chiarcosso.id} or company_id = #{Company.transest.id}").distinct }

  # scope :drivers, -> { include(:relations).where("relations.name = 'Autista'") }
  # scope :company, ->(name) { joins(:companies).where('company.name like ?',"%#{name}%") }
  def check_properties(comp)
    if comp['name'].upcase != self.name.upcase
      return false
    elsif comp['surname'].upcase != self.surname.upcase
      return false
    end
    return true
  end

  def has_reference?(table,id)
    !MssqlReference.where(local_object:self,remote_object_table:table,remote_object_id:id).empty?
  end

  def has_relation?(company,relation)
    !CompanyPerson.where(person: self, company: company, company_relation: relation).empty?
  end

  def self.find_by_complete_name name
    Person.where("lower(concat_ws(' ',surname,name)) = ?", name).first
  end

  def self.find_by_complete_name_inv name
    Person.where("lower(concat_ws(' ',name,surname)) = ?", name).first
  end

  def rearrange_mdc_users user
    self.update(:mdc_user => user)
    unless user.nil?
      Person.where(mdc_user: self.mdc_user).where("id != #{self.id}").update(mdc_user: nil)
    end
    mdc = MdcWebservice.new
    mdc.begin_transaction
    Person.mdc.each do |p|
      mdc.insert_or_update_tabgen(Tabgen.new({deviceCode: "|#{ p.mdc_user.upcase}|", key: p.mdc_user, order: 1, tabname: 'USERS', values: [p.mdc_user.upcase,p.mdc_user,p.name,p.surname,p.id]}))
    end
    mdc.commit_transaction
    mdc.end_transaction
    mdc.close_session
  end

  def self.find_by_mdc_user(user)
    # Person.mdc.where(:mdc_user => user).first
    p = MdcUser.find_by(user: user).assigned_to_person_id
    Person.find(p) unless p.nil?
  end

  def self.find_or_create(person)

    #person -> id: dashboard person id
    #          mssql_id: sql srver id
    #          table: sql server table
    #          data: { name, surname }

    if !person[:id].nil?
      p = Person.find(person[:id].to_i)
      person[:table] = 'Autisti' if person[:table].nil?
      if p.nil? and !person[:data].nil?
        p = Person.create(person[:data])
      end
      unless person[:mssql_id].nil?
        ref = MssqlReference.query({table: person[:table], where: {id: person[:mssql_id], nome: :not_null}}).first
        MssqlReference.create(local_object: p, remote_object_table: person[:table], remote_object_id: person[:mssql_id].to_i)
      end
      return p
    end

    if !person[:mssql_id].nil?
      p = Person.find_by_reference(person[:mssql_id].to_i, person[:table])

      if p.nil?
        case person[:table]
        when 'Autisti' then
          where = {IdAutista: person[:mssql_id].to_i}
        when 'Clienti' then
          where = {IdCliente: person[:mssql_id].to_i}
        end
        ref = MssqlReference.query({table: person[:table], where: where}).first

        case person[:table]
        when 'Autisti' then
          if ref['nome'].nil?
            tmp = ref['Nominativo'].split(/ */,2)
            ref['nome'] = tmp[0]
            ref['cognome'] = tmp[1]
          end
          p = Person.create(name: ref['nome'], surname: ref['cognome'])
        when 'Clienti' then
          tmp = ref['RagioneSociale'].split(/ */,2)
          p = Person.create(name: tmp[0], surname: tmp[1])
        end

        MssqlReference.create(local_object: p, remote_object_table: person[:table], remote_object_id: person[:mssql_id].to_i)
      end
      return p
    end
  end

  def self.find_by_reference(id,table = 'Autisti')
    ms = MssqlReference.find_by(remote_object_id: id.to_i, remote_object_table: table)
    Person.find(ms.local_object_id) unless ms.nil?
  end

  def complete_name
    self.name+' '+self.surname
  end

  def list_name
    self.surname+' '+self.name
  end
end
