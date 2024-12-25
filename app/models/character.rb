class Character < ApplicationRecord
  belongs_to :user
  belongs_to :campaign
  has_many :items

  validates :name,  presence: true, length: { maximum: 50 }

  def assign_user(current_user)
    self.user = current_user
  end

  def self.mod(stat)
    if stat < 4
      -3
    elsif stat < 6
      -2
    elsif stat < 9
      -1
    elsif stat < 13
      0
    elsif stat < 16
      +1
    elsif stat < 18
      +2
    elsif stat == 18
      +3
    end
  end

  private
    def roll_stats
      roller = DiceRoller.new
      rolls = []
      6.times do
        result = roller.roll_multiple_dice(3, 6)
        rolls << result[:total]
      end
    end
end
