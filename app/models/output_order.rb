class OutputOrder < ApplicationRecord
  resourcify
  has_many :order_items
  has_many :items, through: :order_items
  belongs_to :createdBy, class_name: User
  belongs_to :destination, polymorphic: true

  scope :unprocessed, -> { where(:processed => false)}
  scope :processed, -> { where(:processed => true)}

  def items_list
  #   list = Array.new
  #   self.items.each do |i|
  #
  #     f = true
  #
  #     if list[i.article.id.to_sym].nil?
  #       list[(i.article.id.to_s+i..to_sym] = { item: i, count: 1}
  #     else
  #       if i.
  #     end
  #   end
  end
end
