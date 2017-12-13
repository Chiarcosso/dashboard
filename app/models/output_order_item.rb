class OutputOrderItem < ApplicationRecord
  resourcify

  before_destroy :recover_item
  belongs_to :item
  has_one :article, through: :item
  belongs_to :output_order

  def actualPrice
    (self.item.actualPrice / self.item.article.containedAmount) * self.quantity
  end

  def price
    (self.item.price / self.item.article.containedAmount) * self.quantity
  end

  def discount
    self.item.discount
  end

  def complete_price
    price = self.actualPrice.round(2).to_s+' €'
    if (self.item.discount.to_f > 0)
       price += " \n("+self.price.round(2).to_s+' -'+self.discount.to_s+'%'+')'
    end
    price.tr('.',',')#+"\n Scatola: #{self.item.complete_price}"
  end

  def recover_item
    i = self.item
    i.update(remaining_quantity: i.remaining_quantity + self.quantity)
  end

end
