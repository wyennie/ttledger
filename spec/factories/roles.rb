FactoryBot.define do
  factory :role do
    association :user
    association :campaign
    role_type   { :gamemaster }
  end
end
