# frozen_string_literal: true

FactoryBot.define do
  factory :user, class: User do
    sequence(:email) { |n| "user#{n}@example.com" }
    full_name { Faker::Name.name }
    key { SecureRandom.hex(100) }
    metadata { "#{Faker::Demographic.sex}, age #{rand(18..65)}, #{Faker::Job.employment_type}" }
    sequence(:phone_number) { |n| "555123#{n.to_s.rjust(4, '0')}" }
    account_key { SecureRandom.hex(10) }
    password { Faker::Internet.password(min_length: 8) }

    trait :without_full_name do
      full_name { nil }
    end

    trait :without_key do
      key { nil }
    end

    trait :without_account_key do
      account_key { nil }
    end
  end

  factory :user_with_minimum_attributes, class: User do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:phone_number) { |n| "555123#{n.to_s.rjust(4, '0')}" }
    password { Faker::Internet.password(min_length: 8) }
  end
end
