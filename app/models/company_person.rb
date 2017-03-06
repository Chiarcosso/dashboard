class CompanyPerson < ApplicationRecord
  resourcify
  
  belongs_to :person
  belongs_to :company
  belongs_to :company_relation
end
