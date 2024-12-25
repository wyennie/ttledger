FactoryBot.define do
  factory :character do
    name { "Test Character" }
    user
    campaign

    # Minimal required attributes based on schema
    current_hp { 0 }
    max_hp { 0 }
    current_strength { 10 }
    max_strength { 10 }
    current_agility { 10 }
    max_agility { 10 }
    current_stamina { 10 }
    max_stamina { 10 }
    current_personality { 10 }
    max_personality { 10 }
    current_intelligence { 10 }
    max_intelligence { 10 }
    current_luck { 10 }
    max_luck { 10 }

    # Optional attributes with defaults or random values
    description { nil }
    occupation { nil }
    title { nil }
    character_class { nil }
    alignment { nil }
    speed { 30 }
    level { 1 }
    xp { 0 }
    ac { 10 }
    background { nil }
    notes { nil }
    short_term_goals { nil }
    medium_term_goals { nil }
    long_term_goals { nil }
    languages { "Common Tongue" }
    lucky_sign { nil }
    initiative { 0 }
    action_dice { "d20" }
    attack_bonus { 0 }
    crit_die { "d4" }
    crit_table { "Table I" }
    fumble_die { "d4" }
    reflex { 0 }
    fortitude { 0 }
    willpower { 0 }

    # Roll stats using the method in your model
    after(:build) do |character|
      character.assign_user(create(:user)) # Ensure user is created if not provided
      character.campaign ||= create(:campaign) # Ensure campaign is created if not provided
    end
  end
end
