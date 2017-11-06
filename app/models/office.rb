class Office < ApplicationRecord
  resourcify

  has_many :representatives

  scope :filter, ->(search) { where('name like ?',"%#{search}%") }


  def complete_name
    self.name
  end

  def items (*article)
    unless article.empty?
      art_check = "and items.article_id = #{article[0].id}"
    end
    Item.find_by_sql("select * from items inner join output_order_items on items.id = output_order_items.item_id inner join output_orders on output_orders.id = output_order_items.output_order_id where output_orders.id in (select id from output_orders where destination_type = 'Office' and destination_id = #{self.id}) #{art_check.to_s}")
  end

end
