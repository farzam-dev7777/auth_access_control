FactoryBot.define do
  factory :organization do
    name { Faker::Company.name }
    org_type { %w[educational nonprofit corporate community].sample }

    trait :educational do
      org_type { 'educational' }
    end

    trait :nonprofit do
      org_type { 'nonprofit' }
    end

    trait :corporate do
      org_type { 'corporate' }
    end

    trait :community do
      org_type { 'community' }
    end

    trait :allows_minors do
      settings { { 'allow_minors' => true } }
    end

    trait :requires_parental_consent do
      settings { { 'requires_parental_consent' => true } }
    end

    trait :with_age_restrictions do
      settings { { 'min_age' => 13, 'max_age' => 25, 'allow_minors' => true } }
    end
  end
end