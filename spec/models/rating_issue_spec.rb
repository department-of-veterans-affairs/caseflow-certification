# frozen_string_literal: true

require "rails_helper"

describe RatingIssue do
  before do
    Time.zone = "UTC"
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:profile_date) { Time.zone.today - 30 }
  let(:promulgation_date) { Time.zone.today - 30 }
  let(:profile_date) { Time.zone.today - 40 }

  context ".deserialize" do
    subject { RatingIssue.deserialize(rating_issue.serialize) }

    let(:rating_issue) do
      RatingIssue.new(
        reference_id: "NBA",
        participant_id: "123",
        profile_date: profile_date,
        promulgation_date: promulgation_date,
        decision_text: "This broadcast may not be reproduced",
        diagnostic_code: "1234",
        associated_end_products: [],
        rba_contentions_data: [{}]
      )
    end

    it { is_expected.to be_a(RatingIssue) }

    it do
      is_expected.to have_attributes(
        reference_id: "NBA",
        participant_id: "123",
        profile_date: profile_date,
        promulgation_date: promulgation_date,
        decision_text: "This broadcast may not be reproduced",
        diagnostic_code: "1234",
        rba_contentions_data: [{}]
      )
    end
  end

  context ".from_bgs_hash" do
    subject { RatingIssue.from_bgs_hash(rating, bgs_record) }

    let(:associated_claims) do
      [
        { clm_id: "abc123", bnft_clm_tc: "040SCR" },
        { clm_id: "dcf345", bnft_clm_tc: "154IVMC9PMC" }
      ]
    end

    let!(:rating) do
      Generators::Rating.build(
        participant_id: "123",
        promulgation_date: promulgation_date,
        profile_date: profile_date,
        associated_claims: associated_claims
      )
    end

    let(:bgs_record) do
      {
        rba_issue_id: "NBA",
        decn_txt: "This broadcast may not be reproduced",
        dgnstc_tc: "3001"
      }
    end

    it { is_expected.to be_a(RatingIssue) }

    it do
      is_expected.to have_attributes(
        reference_id: "NBA",
        decision_text: "This broadcast may not be reproduced",
        profile_date: profile_date,
        contention_reference_ids: [],
        diagnostic_code: "3001",
        benefit_type: :pension
      )
    end

    context "when rba_issue_contentions is single" do
      let(:bgs_record) do
        {
          rba_issue_id: "NBA",
          decn_txt: "This broadcast may not be reproduced",
          rba_issue_contentions: { prfil_dt: Time.zone.now, cntntn_id: "foul" }
        }
      end

      it do
        is_expected.to have_attributes(
          reference_id: "NBA",
          decision_text: "This broadcast may not be reproduced",
          profile_date: profile_date,
          contention_reference_ids: ["foul"],
          benefit_type: :pension
        )
      end
    end

    context "when rba_issue_contentions is an array" do
      let(:bgs_record) do
        {
          rba_issue_id: "NBA",
          decn_txt: "This broadcast may not be reproduced",
          rba_issue_contentions: [
            { prfil_dt: Time.zone.now, cntntn_id: "foul" },
            { prfil_dt: Time.zone.now, cntntn_id: "dunk" }
          ]
        }
      end

      it do
        is_expected.to have_attributes(
          reference_id: "NBA",
          decision_text: "This broadcast may not be reproduced",
          profile_date: profile_date,
          contention_reference_ids: %w[foul dunk]
        )
      end
    end
  end

  context "#title_of_active_review" do
    before do
      Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
    end

    let(:reference_id) { "abc123" }
    let(:decision_review_type) { "SupplementalClaim" }
    let(:inactive_end_product_establishment) { create(:end_product_establishment, :cleared) }
    let(:active_end_product_establishment) { create(:end_product_establishment, :active) }

    let(:request_issue) do
      create(
        :request_issue,
        end_product_establishment: active_end_product_establishment,
        contested_rating_issue_reference_id: reference_id,
        decision_review_type: decision_review_type
      )
    end

    let(:inactive_request_issue) do
      create(
        :request_issue,
        end_product_establishment: inactive_end_product_establishment,
        contested_rating_issue_reference_id: reference_id,
        decision_review_type: decision_review_type
      )
    end

    it "returns review title if an active RequestIssue already exists with the same reference_id" do
      request_issue
      rating_issue = RatingIssue.new(reference_id: reference_id)

      expect(rating_issue.title_of_active_review).to eq("Supplemental Claim")
    end

    context "removed issue" do
      let(:decision_review_type) { nil }

      it "returns nil if the issue has been removed" do
        request_issue
        rating_issue = RatingIssue.new(reference_id: reference_id)

        expect(rating_issue.title_of_active_review).to be_nil
      end
    end

    it "returns nil if no similar RequestIssue exists" do
      request_issue
      rating_issue = RatingIssue.new(reference_id: "something-else")

      expect(rating_issue.title_of_active_review).to be_nil
    end
  end
end
