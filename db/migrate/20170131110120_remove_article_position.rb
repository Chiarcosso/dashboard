class RemoveArticlePosition < ActiveRecord::Migration[5.0]
  def change
    remove_reference(:articles, :position_code, foreign_key: true)
  end
end
