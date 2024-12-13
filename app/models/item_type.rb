class ItemType < ApplicationRecord
  has_many :items, as: :item_type
end
