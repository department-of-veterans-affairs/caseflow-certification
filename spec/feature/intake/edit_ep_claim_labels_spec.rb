# frozen_string_literal: true

feature "Intake Edit EP Claim Labels", :all_dbs do
  include IntakeHelpers

  before do
    setup_intake_flags
    FeatureToggle.enable!(:edit_ep_claim_labels)
  end

  after do
    FeatureToggle.disable!(:edit_ep_claim_labels)
  end

  let!(:current_user) { User.authenticate!(roles: ["Mail Intake"]) }
  let(:veteran_file_number) { "123412345" }
  let(:veteran) { create(:veteran) }
  let(:receipt_date) { Time.zone.today - 20 }
  let(:profile_date) { 10.days.ago }
  let(:promulgation_date) { 9.days.ago.to_date }
  let!(:rating) { generate_rating_with_defined_contention(veteran, promulgation_date, profile_date) }
  let(:benefit_type) { "compensation" }

  let!(:higher_level_review) do
    create(
      :higher_level_review,
      veteran_file_number: veteran.file_number,
      receipt_date: receipt_date,
      benefit_type: benefit_type,
      legacy_opt_in_approved: false
    )
  end

  # create associated intake
  let!(:intake) do
    create(
      :intake,
      user: current_user,
      detail: higher_level_review,
      veteran_file_number: veteran.file_number,
      started_at: Time.zone.now,
      completed_at: Time.zone.now,
      completion_status: "success",
      type: "HigherLevelReviewIntake"
    )
  end

  let(:rating_request_issue) do
    create(
      :request_issue,
      contested_rating_issue_reference_id: "def456",
      contested_rating_issue_profile_date: rating.profile_date,
      decision_review: higher_level_review,
      benefit_type: benefit_type,
      contested_issue_description: "PTSD denied"
    )
  end

  let(:nonrating_request_issue) do
    create(
      :request_issue,
      :nonrating,
      decision_review: higher_level_review,
      benefit_type: benefit_type,
      contested_issue_description: "Apportionment"
    )
  end

  let(:ineligible_request_issue) do
    create(
      :request_issue,
      :nonrating,
      :ineligible,
      decision_review: higher_level_review,
      benefit_type: benefit_type,
      contested_issue_description: "Ineligible issue"
    )
  end

  let(:withdrawn_request_issue) do
    create(
      :request_issue,
      :nonrating,
      :withdrawn,
      decision_review: higher_level_review,
      contested_issue_description: "Issue that's been withdrawn"
    )
  end

  context "When editing a decision review with end products" do
    before do
      higher_level_review.create_issues!(
        [
          rating_request_issue,
          nonrating_request_issue,
          ineligible_request_issue,
          withdrawn_request_issue
        ]
      )
      higher_level_review.establish!
    end

    it "shows each established end product label" do
      visit "higher_level_reviews/#{higher_level_review.uuid}/edit"

      # First shows issues on end products, in ascending order by EP code
      # Note for these, there's a row for the EP, and another for the issues
      row = find("#table-row-8")
      label = Constants::EP_CLAIM_TYPES[nonrating_request_issue.end_product_establishment.code]["official_label"]
      expect(row).to have_content(label)
      expect(row).to have_button("Edit claim label")
      expect(find("#table-row-9")).to have_content(/Requested issues\n1. #{nonrating_request_issue.description}/i)

      label = Constants::EP_CLAIM_TYPES[rating_request_issue.end_product_establishment.code]["official_label"]
      row = find("#table-row-10")
      expect(row).to have_content(label)
      expect(row).to have_button("Edit claim label")
      expect(find("#table-row-11")).to have_content(/Requested issues\n2. #{rating_request_issue.description}/i)

      # Shows issues not on end products (single row)
      row = find("#table-row-12")
      expect(row).to have_content(/Requested issues\n3. #{ineligible_request_issue.description}/i)

      # Shows withdrawn issues last (single row)
      row = find("#table-row-13")
      expect(row).to have_content(
        /Withdrawn issues\n4. #{withdrawn_request_issue.description}/i
      )
    end
  end
end