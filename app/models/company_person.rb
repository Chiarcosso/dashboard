class CompanyPerson < ApplicationRecord
  belongs_to :person
  belongs_to :company
  belongs_to :company_relation
end
