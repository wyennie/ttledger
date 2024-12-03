FactoryBot.define do
  factory :item do
    name { "MyString" }
    weight { "MyString" }
    value { "MyString" }
    count { 1 }
    character { nil }
  end
end
