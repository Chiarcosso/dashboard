class Office < ApplicationRecord
  resourcify

  has_many :representatives

  scope :filter, ->(search) { where('name like ?',"%#{search}%") }

  def self.mobile_workshops(number = nil)
    if number.nil?
      Office.where("offices.name like 'Officina mobile%'")
    else
      Office.find_by_name('Officina mobile '+number.to_s)
    end
  end

  def complete_name
    self.name
  end

  def items (*article)
    # article[0] -> specifies article
    # article[1] -> already assigned articles
    # article[2] -> limit items amount
    unless article[0].nil?
      art_check = "and items.article_id = #{article[0].id}"
    end

    unless article[2].nil?
      limit = "limit #{article[2]}"
    end
    list = Item.find_by_sql("select * from items inner join output_order_items on items.id = output_order_items.item_id inner join output_orders on output_orders.id = output_order_items.output_order_id where output_orders.id in (select id from output_orders where destination_type = 'Office' and destination_id = #{self.id}) #{art_check.to_s} order by output_order_items.created_at asc")
    unless article[1].nil?
      list -= article[1]
    end
    list
  end

end
