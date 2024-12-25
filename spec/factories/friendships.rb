FactoryBot.define do
  factory :friendship do
    sender { create(:user) }  # Automatically creates a sender user
    receiver { create(:user) }  # Automatically creates a receiver user
    status { "pending" }  # Default status is 'pending'

    # Optionally, traits can be used to set different statuses
    trait :accepted do
      status { "accepted" }
    end

    trait :denied do
      status { "denied" }
    end

    # Helper trait for creating a unique friendship (ensuring sender and receiver are different)
    trait :unique_friendship do
      after(:create) do |friendship|
        friendship.receiver = create(:user)
        friendship.sender = create(:user)
      end
    end
  end
end
