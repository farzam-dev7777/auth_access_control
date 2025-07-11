FactoryBot.define do
  factory :parental_consent do
    association :user
    parent_email { Faker::Internet.email }
    consent_token { SecureRandom.urlsafe_base64(32) }
    consent_requested_at { Time.current }
    expires_at { 7.days.from_now }
    consented { false }

    trait :granted do
      consented { true }
      consented_at { Time.current }
    end

    trait :denied do
      consented { false }
      notes { 'Parent denied consent' }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end
  end
end
