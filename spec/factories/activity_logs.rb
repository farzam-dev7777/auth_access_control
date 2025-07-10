FactoryBot.define do
  factory :activity_log do
    association :user
    association :organization
    action { 'user_login' }
    performed_at { Time.current }
    metadata { {} }

    trait :user_login do
      action { 'user_login' }
    end

    trait :member_joined do
      action { 'member_joined' }
      metadata { { 'role' => 'member' } }
    end

    trait :event_created do
      action { 'event_created' }
    end

    trait :consent_granted do
      action { 'consent_granted' }
    end

    trait :consent_denied do
      action { 'consent_denied' }
    end

    trait :rule_created do
      action { 'rule_created' }
      metadata { { 'rule_type' => 'event_creation' } }
    end
  end
end