class Role < ApplicationRecord
  belongs_to :user
  belongs_to :campaign

  enum role_type: { gamemaster: 0, player: 1 }
end
