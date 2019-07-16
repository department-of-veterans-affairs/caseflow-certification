# frozen_string_literal: true

class Api::V3::DecisionReview::HigherLevelReviewsController < ActionController::Base
  protect_from_forgery with: :null_session

  def create
    mock_hlr = HigherLevelReview.new(
      uuid: 'FAKEuuid-mock-test-fake-mocktestdata',
      establishment_submitted_at: Time.zone.now # having this timestamp marks it as submitted
    )
    response.set_header('Content-Location', "#{request.base_url}/api/v3/decision_review/higher_level_reviews/intake_status/999") #FIXME should be an intake id
    render json: intake_status(mock_hlr), status: 202
  end

private
  def intake_status(higher_level_review)
    {
      data: {
        type: 'IntakeStatus',
        id: higher_level_review.uuid,
        attributes: {
          status: higher_level_review.asyncable_status
        }
      }
    }
  end
end