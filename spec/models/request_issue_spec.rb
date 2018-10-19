require "rails_helper"

describe RequestIssue do
  let(:review) { create(:higher_level_review, veteran_file_number: veteran.file_number) }
  let!(:veteran) { Generators::Veteran.build(file_number: "789987789") }

  let!(:rated_issue) do
    RequestIssue.create(
      review_request: review,
      rating_issue_reference_id: "abc123",
      rating_issue_profile_date: Time.zone.now,
      description: "a rated issue"
    )
  end

  let!(:non_rated_issue) do
    RequestIssue.create(
      review_request: review,
      description: "a non-rated issue description",
      issue_category: "a category",
      decision_date: 1.day.ago
    )
  end

  let!(:unidentified_issue) do
    RequestIssue.create(
      review_request: review,
      description: "an unidentified issue",
      is_unidentified: true
    )
  end

  context "finds issues" do
    it "filters by rated issues" do
      rated_issues = RequestIssue.rated
      expect(rated_issues.length).to eq(2)
      expect(rated_issues.find_by(id: rated_issue.id)).to_not be_nil
      expect(rated_issues.find_by(id: unidentified_issue.id)).to_not be_nil
    end

    it "filters by nonrated issues" do
      non_rated_issues = RequestIssue.nonrated
      expect(non_rated_issues.length).to eq(1)
      expect(non_rated_issues.find_by(id: non_rated_issue.id)).to_not be_nil
    end

    it "filters by unidentified issues" do
      unidentified_issues = RequestIssue.unidentified
      expect(unidentified_issues.length).to eq(1)
      expect(unidentified_issues.find_by(id: unidentified_issue.id)).to_not be_nil
    end

    context ".find_active_by_reference_id" do
      let(:active_rated_issue) do
        rated_issue.tap { |ri| ri.update!(end_product_establishment: create(:end_product_establishment, :active)) }
      end

      context "EPE is active" do
        let(:rating_issue) { RatingIssue.new(reference_id: active_rated_issue.rating_issue_reference_id) }

        it "filters by reference_id" do
          request_issue_in_review = RequestIssue.find_active_by_reference_id(rating_issue.reference_id)
          expect(request_issue_in_review).to eq(rated_issue)
        end

        it "ignores request issues that are already ineligible" do
          create(
            :request_issue,
            rating_issue_reference_id: rated_issue.rating_issue_reference_id,
            ineligible_reason: :duplicate_of_issue_in_active_review
          )

          request_issue_in_review = RequestIssue.find_active_by_reference_id(rating_issue.reference_id)
          expect(request_issue_in_review).to eq(rated_issue)
        end
      end

      context "EPE is not active" do
        let(:rating_issue) { RatingIssue.new(reference_id: rated_issue.rating_issue_reference_id) }

        it "ignores request issues" do
          expect(RequestIssue.find_active_by_reference_id(rating_issue.reference_id)).to be_nil
        end
      end
    end
  end

  context "#contention_text" do
    it "changes based on is_unidentified" do
      expect(unidentified_issue.contention_text).to eq(RequestIssue::UNIDENTIFIED_ISSUE_MSG)
      expect(rated_issue.contention_text).to eq("a rated issue")
      expect(non_rated_issue.contention_text).to eq("a category - a non-rated issue description")
    end
  end

  context "#review_title" do
    it "munges the review_request_type appropriately" do
      expect(rated_issue.review_title).to eq "Higher-Level Review"
    end
  end
end
