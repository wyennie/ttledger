class Character < ApplicationRecord
  belongs_to :user
  belongs_to :campaign
  has_many :items
  has_one :character_stat, dependent: :destroy
  has_one :character_derived_stat, dependent: :destroy
  accepts_nested_attributes_for :character_stat
  accepts_nested_attributes_for :character_derived_stat

  validates :name,  presence: true, length: { maximum: 50 }

  after_create :create_character_stats
  after_create :create_character_derived_stats

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
    def create_character_stats
      roller = DiceRoller.new
      rolls = []
      6.times do
        result = roller.roll_multiple_dice(3, 6)
        rolls << result[:total]
      end

      self.create_character_stat(
        strength_current: rolls[0], strength_max: rolls[0], strength_modifier: 0,
        agility_current: rolls[1], agility_max: rolls[1], agility_modifier: 0,
        stamina_current: rolls[2], stamina_max: rolls[2], stamina_modifier: 0,
        personality_current: rolls[3], personality_max: rolls[3], personality_modifier: 0,
        intelligence_current: rolls[4], intelligence_max: rolls[4], intelligence_modifier: 0,
        luck_current: rolls[5], luck_max: rolls[5], luck_modifier: 0
      )
    end

    def create_character_derived_stats
      self.create_character_derived_stat(
        initiative: 0, action_dice: "1d20", attack_dice: "", crit_die: "",
        crit_table: "", fumble_die: "", fumble_table: "", reflex: 0, fortitude: 0, willpower: 0
      )
    end
end
