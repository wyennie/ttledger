class Container < ApplicationRecord
  has_one :item, as: :item_type
end
