FactoryBot.define do
  factory :participation_rule do
    association :organization
    rule_type { 'event_creation' }
    description { 'Test rule' }
    active { true }
    priority { 1 }
    conditions { {} }

    trait :event_creation do
      rule_type { 'event_creation' }
    end

    trait :content_posting do
      rule_type { 'content_posting' }
    end

    trait :member_invitation do
      rule_type { 'member_invitation' }
    end

    trait :role_assignment do
      rule_type { 'role_assignment' }
    end

    trait :content_access do
      rule_type { 'content_access' }
    end

    trait :age_restriction do
      rule_type { 'age_restriction' }
      conditions { { 'minimum_age' => 13, 'maximum_age' => 25 } }
    end

    trait :inactive do
      active { false }
    end

    trait :high_priority do
      priority { 10 }
    end
  end
end
