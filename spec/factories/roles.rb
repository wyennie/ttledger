FactoryBot.define do
  factory :role do
    user { nil }
    campaign { nil }
    role_type { 1 }
  end
end
