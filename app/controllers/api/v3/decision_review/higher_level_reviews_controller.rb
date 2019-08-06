# frozen_string_literal: true

class Api::V3::DecisionReview::HigherLevelReviewsController < ActionController::Base
  protect_from_forgery with: :null_session

  def create
    processor = Api::V3::HigherLevelReviewProcessor.new(params, current_user)
    if processor.errors?
      render self.class.errors_to_render_args(processor.errors)
      return
    end

    processor.start_review_complete!
    if processor.errors?
      render self.class.errors_to_render_args(processor.errors)
      return
    end

    hlr = processor.higher_level_review

    response.set_header(
      "Content-Location",
      "#{request.base_url}/api/v3/decision_review/higher_level_reviews/intake_status/#{hlr.uuid}"
    )

    render json: self.class.intake_status(hlr), status: :accepted
  rescue StandardError => error
    # do we want something like intakes_controller's log_error here?
    render self.class.errors_to_render_args([self.class.error_from_objects_error_code(error, processor.intake)])
  end

  class << self
    def intake_status(higher_level_review)
      {
        data: {
          type: "IntakeStatus",
          id: higher_level_review.uuid,
          attributes: {
            status: higher_level_review.asyncable_status
          }
        }
      }
    end

    # errors should be an array of Api::V3::HigherLevelReviewProcessor::Error
    def errors_to_render_args(errors)
      fail ArgumentError, "errors_to_render_args expects 1 array argument" if errors == {}

      { json: { errors: errors }, status: errors.map { |e| Integer e.status }.max || 422 }
    end

    # given multiple objects, will return the error for the first error code it can find
    def error_from_objects_error_code(*args)
      args.each do |arg|
        code = arg.try(:error_code)
        return Api::V3::HigherLevelReviewProcessor.error_from_error_code(code) if code
      end
      Api::V3::HigherLevelReviewProcessor.error_from_error_code(nil)
    end
  end
end

# def mock_create
#   mock_hlr = HigherLevelReview.new(
#     uuid: "FAKEuuid-mock-test-fake-mocktestdata",
#     establishment_submitted_at: Time.zone.now # having this timestamp marks it as submitted
#   )
#   response.set_header(
#     "Content-Location",
#     # id returned is static, if a mock intake_status is created, this should match
#     "#{request.base_url}/api/v3/decision_review/higher_level_reviews/intake_status/999"
#   )
#   render json: intake_status(mock_hlr), status: :accepted
# end
