FactoryBot.define do
  factory :character do
    name { "MyString" }
    description { "MyText" }
    stats { "" }
    user { nil }
    campaign { nil }
  end
end
