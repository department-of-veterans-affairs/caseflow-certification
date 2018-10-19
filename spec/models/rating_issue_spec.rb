require "rails_helper"

describe RatingIssue do
  before do
    FeatureToggle.enable!(:test_facols)
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  context ".from_bgs_hash" do
    subject { RatingIssue.from_bgs_hash(bgs_record) }

    let(:bgs_record) do
      {
        rba_issue_id: "NBA",
        decn_txt: "This broadcast may not be reproduced"
      }
    end

    it { is_expected.to be_a(RatingIssue) }

    it do
      is_expected.to have_attributes(
        reference_id: "NBA",
        decision_text: "This broadcast may not be reproduced",
        profile_date: nil,
        contention_reference_id: nil
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
          profile_date: Time.zone.now,
          contention_reference_id: "foul"
        )
      end
    end

    context "when rba_issue_contentions is an array" do
      let(:bgs_record) do
        {
          rba_issue_id: "NBA",
          decn_txt: "This broadcast may not be reproduced",
          rba_issue_contentions: [{ prfil_dt: Time.zone.now, cntntn_id: "foul" }]
        }
      end

      it do
        is_expected.to have_attributes(
          reference_id: "NBA",
          decision_text: "This broadcast may not be reproduced",
          profile_date: Time.zone.now,
          contention_reference_id: "foul"
        )
      end
    end
  end

  context "#in_active_review" do
    before do
      Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
    end

    let(:reference_id) { "abc123" }
    let(:review_request_type) { "SupplementalClaim" }
    let(:inactive_end_product_establishment) { create(:end_product_establishment, :cleared) }
    let(:active_end_product_establishment) { create(:end_product_establishment, :active) }

    let(:request_issue) do
      create(
        :request_issue,
        end_product_establishment: active_end_product_establishment,
        rating_issue_reference_id: reference_id,
        review_request_type: review_request_type
      )
    end

    let(:inactive_request_issue) do
      create(
        :request_issue,
        end_product_establishment: inactive_end_product_establishment,
        rating_issue_reference_id: reference_id,
        review_request_type: review_request_type
      )
    end

    it "returns review title if an active RequestIssue already exists with the same reference_id" do
      request_issue
      rating_issue = RatingIssue.new(reference_id: reference_id)

      expect(rating_issue.in_active_review).to eq("Supplemental Claim")
    end

    context "removed issue" do
      let(:review_request_type) { nil }

      it "returns nil if the issue has been removed" do
        request_issue
        rating_issue = RatingIssue.new(reference_id: reference_id)

        expect(rating_issue.in_active_review).to be_nil
      end
    end

    it "returns nil if no similar RequestIssue exists" do
      request_issue
      rating_issue = RatingIssue.new(reference_id: "something-else")

      expect(rating_issue.in_active_review).to be_nil
    end

    it "returns nil if similar RequestIssue exists for inactive EPE" do
      inactive_request_issue
      rating_issue = RatingIssue.new(reference_id: reference_id)

      expect(rating_issue.in_active_review).to be_nil
    end
  end

  context "#save_with_request_issue!" do
    let(:contention_ref_id) { 123 }

    let!(:request_issue) { create(:request_issue, contention_reference_id: contention_ref_id) }

    it "matches based on contention_reference_id" do
      rating_issue = RatingIssue.new(
        reference_id: "ref-id",
        profile_date: Time.zone.today,
        contention_reference_id: contention_ref_id
      )

      expect(rating_issue.id).to be_nil

      rating_issue.save_with_request_issue!

      expect(rating_issue.request_issue).to eq(request_issue)
      expect(rating_issue.id).to_not be_nil
    end
  end
end
