FactoryBot.define do
  factory :message do
    campaign { nil }
    user { nil }
    content { "MyText" }
  end
end
