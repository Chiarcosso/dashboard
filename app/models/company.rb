class Company < ApplicationRecord
  resourcify

  belongs_to :company_group
  belongs_to :parent_company, foreign_key: :parent_company_id, class_name: :company
  belongs_to :main_phone_number
  belongs_to :main_mail_address
  belongs_to :main_pec_address
  belongs_to :main_address, foreign_key: :main_company_address_id, class_name: :CompanyAddress

  has_many :owned_vehicles, foreign_key: :property_id, class_name: 'Vehicle'
  has_many :worksheets, through: :owned_vehicles
  has_many :produced_vehicles, foreign_key: :manufacturer_id, class_name: 'Vehicle'
  has_many :produced_articles, foreign_key: :manufacturer_id, class_name: 'Article'
  has_many :items, through: :produced_articles

  has_many :company_addresses
  has_many :company_mail_addresses
  has_many :company_pec_addresses
  has_many :company_phone_numbers

  has_many :vehicle_properties, as: :owner

  scope :filter, ->(search) { where('name like ?',"%#{search}%").order(:name) }
  scope :not_us, -> { where("name not like 'Autotrasporti Chiarcosso%' and name not like 'Trans Est%'")}
  scope :most_used_transporter, -> { where("transporter = 1 and id in "\
    "(select a.owner_id from "\
      "(select owner_id, count(external_vehicles.id) as count "\
        "from external_vehicles group by owner_id order by count(external_vehicles.id) desc) as a )") }
  # scope :find_by_name,->(name) { where("lower(name) = ?", name) }
  def self.chiarcosso
    Company.where("name like 'Autotrasporti Chiarcosso%'").first
  end

  def self.edilizia
    Company.where("name like 'Edilizia Chiarcosso%'").first
  end

  def self.transest
    Company.where("name like 'Trans Est%'").first
  end

  def self.not_available
    nd = Company.find_by(name: 'N/D')
    nd = Company.create(name: 'N/D') if nd.nil?
    nd
  end

  def self.find_by_reference(table,id)
    v = MssqlReference.find_by(remote_object_table: table, remote_object_id: id)
	  v.local_object unless v.nil?
    # find and create new vehicle if v.nil?
  end
  # def self.most_used_transporter
  #   Company..first
  # end
  def has_reference?(table,id)
    !MssqlReference.where(local_object:self,remote_object_table:table,remote_object_id:id).empty?
  end
  
  def check_properties(comp)
    if comp['name'] != self.name
      return false
    end
    if comp['vat_number'] != self.vat_number
      return false
    end
    return true
  end

  def to_worksheet_financial_csv(options = {},year = Date.current.year)
    CSV.generate(options) do |csv|
      csv << ['Ditta: ',self.name]
      columns = ['Scheda','Targa','Data','Totale ricambi','Totale minuteria','Totale ore','Totale']
      csv << columns
      # csv << column_names
      list = self.worksheets.year(year).each_with_index.map{ |ws,i| [ws.code,ws.vehicle.plate,ws.created_at.strftime("%d/%m/%Y"),ws.items_price.round(2).to_s.tr('.',','),ws.materials_price.round(2).to_s.tr('.',','),ws.hours_price.round(2).to_s.tr('.',','),"=SOMMA(D#{i+3}:F#{i+3})"]}
      list.each do |worksheet|
        # csv << article.values_at(*columns)
        # csv << [article[:name],article[:availability],article[:price],article[:total]].values_at(*columns)
        csv << worksheet
      end
      csv << ['','','','','','Totale',"=SOMMA(G3:G#{list.size+2})"]
    end
  end

  def self.financial_list
    worksheets = Array.new
    Worksheet.year().each do |a|
      articles << [a.complete_name,a.availability.size,a.actual_prices_label,a.actual_total.round(2).to_s.tr('.',',')]
    end
    articles
  end

  def total_workheets_price
    total = 0.0
    self.owned_vehicles.each do |v|
      total += v.worksheets.map{ |ws| ws.total_price }.inject(0,:+)
    end
    total
  end

  def self.manufacturerChoice
    find_by_sql('select companies.*, vehicle_models.manufacturer_id as id, count(vehicle_models.manufacturer_id) as cnt from vehicle_models inner join companies on companies.id = vehicle_models.manufacturer_id group by manufacturer_id having manufacturer_id is not null order by cnt desc').first
  end

  def self.propertyChoice
    find_by_sql('select companies.*, vehicles.property_id as id, count(vehicles.property_id) as cnt from vehicles inner join companies on companies.id = vehicles.property_id group by property_id having property_id is not null order by cnt desc').first
  end

  def self.find_by_name name
    Company.where("lower(name) = ?", name).first
  end

  def self.get(id)
    unless id.nil? or id == ''
      Company.find(id)
    else
      nil
    end
  end

  def show_categories
    cats = Array.new
    cats << 'officina' if self.workshop
    cats << 'trasportatore' if self.transporter
    cats << 'cliente' if self.client
    cats << 'fornitore' if self.supplier
    cats << 'produttore di veicoli' if self.vehicle_manufacturer
    cats << 'produttore di materiali' if self.item_manufacturer
    cats << 'istituzione' if self.institution
    cats << 'istituto di formazione' if self.formation_institute
    cats.join(', ').capitalize
  end

  def main_phone_number
    pn = self.main_phone_number
    pn.international_prefix+' '+pn.prefx+' '+pn.number
  end

  def main_mail_address
    self.main_mail_address.address
  end

  def pec_mail_address
    self.pec_mail_address.address
  end

  def list_name
    self.name
  end

  def complete_name
    self.name
  end

  def to_s
    self.complete_name
  end

end
