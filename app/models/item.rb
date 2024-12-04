class Item < ApplicationRecord
  belongs_to :character

  validates :name,  presence: true, length: { maximum: 50 }
end
