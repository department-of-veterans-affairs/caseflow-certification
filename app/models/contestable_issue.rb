# Container class representing any type of issue that can be contested by a decision review
class ContestableIssue
  include ActiveModel::Model

  attr_accessor :rating_issue_reference_id, :date, :description, :ramp_claim_id, :contesting_decision_review,
                :decision_issue_id, :promulgation_date, :rating_issue_profile_date, :source_request_issues,
                :rating_issue_disability_code

  class << self
    def from_rating_issue(rating_issue, contesting_decision_review)
      new(
        rating_issue_reference_id: rating_issue.reference_id,
        rating_issue_profile_date: rating_issue.profile_date.to_date,
        date: rating_issue.profile_date.to_date,
        description: rating_issue.decision_text,
        ramp_claim_id: rating_issue.ramp_claim_id,
        source_request_issues: rating_issue.source_request_issues,
        contesting_decision_review: contesting_decision_review,
        rating_issue_disability_code: rating_issue.disability_code
      )
    end

    def from_decision_issue(decision_issue, contesting_decision_review)
      new(
        rating_issue_reference_id: decision_issue.rating_issue_reference_id,
        rating_issue_profile_date: decision_issue.profile_date.try(:to_date),
        decision_issue_id: decision_issue.id,
        date: decision_issue.approx_decision_date,
        description: decision_issue.description,
        source_request_issues: decision_issue.request_issues,
        contesting_decision_review: contesting_decision_review
      )
    end
  end

  def serialize
    {
      ratingIssueReferenceId: rating_issue_reference_id,
      ratingIssueProfileDate: rating_issue_profile_date,
      ratingIssueDisabilityCode: rating_issue_disability_code,
      decisionIssueId: decision_issue_id,
      date: date,
      description: description,
      rampClaimId: ramp_claim_id,
      titleOfActiveReview: title_of_active_review,
      sourceReviewType: source_review_type,
      timely: timely?,
      latestIssueInChain: serialize_latest_decision_issue_in_chain
    }
  end

  def source_review_type
    return unless source_request_issues.first

    decision_issue? ? source_request_issues.first.decision_review_type : source_request_issues.first.review_request_type
  end

  private

  def serialize_latest_decision_issue_in_chain
    return {id: nil, date: nil} unless latest_decision_issue_in_chain

    {
      id: latest_decision_issue_in_chain.id,
      date: latest_decision_issue_in_chain.caseflow_decision_date
    }
  end

  def latest_decision_issue_in_chain
    @latest_decision_issue_in_chain ||= ContestableIssueChain.latest_decision_issue_in_chain(self)
  end

  def decision_issue?
    !!decision_issue_id
  end

  def title_of_active_review
    conflicting_request_issue.try(:review_title)
  end

  def conflicting_request_issue_by_rating
    return unless rating_issue_reference_id

    potentially_conflicting_request_issues.find_active_by_contested_rating_issue_reference_id(rating_issue_reference_id)
  end

  def conflicting_request_issue_by_decision_issue
    return unless decision_issue_id

    potentially_conflicting_request_issues.find_active_by_contested_decision_id(decision_issue_id)
  end

  def potentially_conflicting_request_issues
    RequestIssue.where.not(review_request: contesting_decision_review)
  end

  def conflicting_request_issue
    return unless contesting_decision_review

    found_request_issue = conflicting_request_issue_by_decision_issue || conflicting_request_issue_by_rating

    return unless different_decision_review(found_request_issue)

    found_request_issue
  end

  def different_decision_review(found_request_issue)
    return unless found_request_issue

    found_request_issue.review_request_id != contesting_decision_review.id ||
      found_request_issue.review_request_type != contesting_decision_review.class.name
  end

  def timely?
    date && contesting_decision_review.timely_issue?(date)
  end
end
