class Mention < ApplicationRecord
  belongs_to :entity
  belongs_to :mentionable, polymorphic: true
end
