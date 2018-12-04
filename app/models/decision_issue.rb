class DecisionIssue < ApplicationRecord
  validates :disposition, inclusion: { in: Constants::ISSUE_DISPOSITIONS_BY_ID.keys.map(&:to_s) },
                          allow_nil: true, if: :appeal?
  has_many :request_decision_issues, dependent: :destroy
  has_many :request_issues, through: :request_decision_issues
  has_many :remand_reasons, dependent: :destroy
  belongs_to :decision_review, polymorphic: true

  def title_of_active_review
    request_issue = RequestIssue.find_active_by_contested_decision_id(id)
    request_issue.review_title if request_issue
  end

  private

  def appeal?
    decision_review_type == Appeal.to_s
  end
end
