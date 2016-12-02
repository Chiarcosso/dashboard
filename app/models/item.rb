class Item < ApplicationRecord
  resourcify

  belongs_to :article
  belongs_to :transportDocument

  enum state: [:nuovo,:usato,:rigenerato,:riscolpito,:smaltimento]

  @amount = 1

  def amount
    @amount
  end
end
