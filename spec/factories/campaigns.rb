FactoryBot.define do
  factory :campaign do
    name { Faker::Company.name }
    description { "This is a test campaign description." }

    # Associations
    after(:create) do |campaign|
      # Optionally, associate users with the campaign
      create(:user, campaigns: [ campaign ]) # Creates a user and associates them with the campaign
    end
  end
end
