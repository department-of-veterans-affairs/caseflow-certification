class RequestIssue < ApplicationRecord
  belongs_to :review_request, polymorphic: true
  belongs_to :end_product_establishment
  has_many :decision_issues
  has_many :remand_reasons

  def self.rated
    where.not(rating_issue_reference_id: nil, rating_issue_profile_date: nil)
      .or(where(issue_category: "Unknown issue category"))
  end

  def self.nonrated
    where(rating_issue_reference_id: nil, rating_issue_profile_date: nil)
      .where.not(issue_category: [nil, "Unknown issue category"])
  end

  def self.no_follow_up_issues
    where.not(id: select(:parent_request_issue_id).uniq)
  end

  def rated?
    rating_issue_reference_id && rating_issue_profile_date
  end

  def self.from_intake_data(data)
    new(
      rating_issue_reference_id: data[:reference_id],
      rating_issue_profile_date: data[:profile_date],
      description: data[:decision_text],
      decision_date: data[:decision_date],
      issue_category: data[:issue_category],
      notes: data[:notes]
    )
  end

  def ui_hash
    {
      reference_id: rating_issue_reference_id,
      profile_date: rating_issue_profile_date,
      description: description,
      decision_date: decision_date,
      category: issue_category,
      notes: notes
    }
  end
end
