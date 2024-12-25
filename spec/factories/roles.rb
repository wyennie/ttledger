FactoryBot.define do
  factory :role do
    user
    campaign
    role_type { :player }  # Default role type is 'player'

    # You can optionally set the role type as 'gamemaster' using the following:
    # role_type { :gamemaster }
  end
end
