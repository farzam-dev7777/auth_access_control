FactoryBot.define do
  factory :membership do
    association :user
    association :organization
    role { 'member' }

    trait :admin do
      role { 'admin' }
    end

    trait :moderator do
      role { 'moderator' }
    end

    trait :member do
      role { 'member' }
    end
  end
end