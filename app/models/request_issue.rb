class RequestIssue < ApplicationRecord
  belongs_to :review_request, polymorphic: true

  def self.create_from_intake_data!(data)
    create!(
      rating_issue_reference_id: data[:reference_id],
      rating_issue_profile_date: data[:profile_date],
      description: data[:decision_text],
      decision_date: data[:decision_date],
      issue_category: data[:issue_category]
    )
  end

  # def contention=(contention)
  #   self.contention_reference_id = contention.id
  #   self.description = contention.text
  # end
end
