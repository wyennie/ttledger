FactoryBot.define do
  factory :armor do
    ac_bonus { 2 }
    check_penalty { -1 }
    speed_penalty { -5 }
    fumble_die { "1d6" }

    after(:create) do |armor|
      create(:item, item_type: armor)
    end
  end
end
