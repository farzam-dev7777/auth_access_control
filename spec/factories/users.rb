FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    date_of_birth { 25.years.ago }

    trait :minor do
      date_of_birth { 15.years.ago }
    end

    trait :child do
      date_of_birth { 10.years.ago }

      # Skip validation for test purposes
      to_create { |instance| instance.save(validate: false) }
    end

    trait :teen do
      date_of_birth { 16.years.ago }
    end

    trait :adult do
      date_of_birth { 25.years.ago }
    end

    trait :suspended do
      suspended { true }
      suspended_at { Time.current }
      suspended_reason { 'Violation of terms' }
    end
  end
end
