FactoryBot.define do
  factory :campaign_invitation do
    campaign
    sender { create(:user) }  # Automatically creates a user for the sender
    receiver { create(:user) }  # Automatically creates a user for the receiver
    status { :pending }  # Default status is 'pending'

    # Optionally, you can use the following to customize status:
    # status { :accepted }
    # status { :declined }

    # Ensures the combination of receiver and campaign is unique
    # For the uniqueness validation of receiver_id, you can use traits to customize
    trait :accepted do
      status { :accepted }
    end

    trait :declined do
      status { :declined }
    end

    # Additional helper for creating multiple invitations with unique receiver/campaign combos
    trait :unique_invitation do
      after(:create) do |invitation|
        invitation.receiver = create(:user)
        invitation.campaign = create(:campaign)
      end
    end
  end
end
