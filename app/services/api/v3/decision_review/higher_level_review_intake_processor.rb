# frozen_string_literal: true

class Api::V3::DecisionReview::HigherLevelReviewIntakeProcessor < Api::V3::DecisionReview::IntakeProcessor
  def initialize(params, user)
    super(params: params, user: user, form_type: "higher_level_review")
  end

  alias higher_level_review detail
end
