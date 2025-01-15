FactoryBot.define do
  factory :chat_message do
    content { "MyText" }
    role { "MyString" }
    page { nil }
    campaign { nil }
    user { nil }
  end
end
