# frozen_string_literal: true

FactoryBot.define do
  factory :higher_level_review do
    sequence(:veteran_file_number, &:to_s)
    receipt_date { 1.month.ago }
    benefit_type { "compensation" }

    trait :with_end_product_establishment do
      after(:create) do |higher_level_review|
        create(:end_product_establishment, source: higher_level_review)
      end
    end

    trait :requires_processing do
      establishment_submitted_at { (HigherLevelReview.processing_retry_interval_hours + 1).hours.ago }
      establishment_last_submitted_at { (HigherLevelReview.processing_retry_interval_hours + 1).hours.ago }
      establishment_processed_at { nil }
    end
  end
end
