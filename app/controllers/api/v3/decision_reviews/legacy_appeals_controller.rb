# frozen_string_literal: true

class Api::V3::DecisionReviews::LegacyAppealsController < Api::V3::BaseController
  include ApiV3FeatureToggleConcern

  SSN_REGEX = /^\d{9}$/.freeze

  before_action only: [:index] do
    api_released?(:api_v3_legacy_appeals)
  end

  before_action :validate_veteran_ssn, :validate_veteran_presence

  def index
    render json: serialized_legacy_appeals
  end

  private

  def validate_veteran_ssn
    return unless veteran_ssn

    render_invalid_veteran_ssn unless veteran_ssn.match?(SSN_REGEX)
    ssn_formatted_correctly?
  end

  def validate_veteran_presence
    render_veteran_not_found unless veteran
  end

  def veteran
    ssn_or_file_number = veteran_ssn || request.headers["X-VA-File-Number"]
    @veteran ||= Veteran.find_by_file_number_or_ssn(ssn_or_file_number)
  end

  def veteran_ssn
    @veteran_ssn ||= request.headers["X-VA-SSN"]
  end

  def veteran_valid?
    render_veteran_not_found unless veteran
  end

  def ssn_formatted_correctly?
    return unless veteran_ssn

    render_invalid_veteran_ssn unless veteran_ssn.match?(SSN_REGEX)
  end

  def render_invalid_veteran_ssn
    render_errors(
      status: 422,
      code: :invalid_veteran_ssn,
      title: "Invalid Veteran SSN",
      detail: "SSN regex: #{SSN_REGEX.inspect})."
    )
  end

  def render_veteran_not_found
    render_errors(
      status: 404,
      code: :veteran_not_found,
      title: "Veteran Not Found"
    )
  end

  def render_missing_headers
    render_errors(
      status: 422,
      code: :missing_identifying_headers,
      title: "Veteran file number or SSN header is required"
    )
  end

  def legacy_appeals
    veteran_appeals = LegacyAppeal.fetch_appeals_by_file_number(veteran.file_number)
    @legacy_appeals ||= veteran_appeals.select(&:active?)
  end

  def serialized_legacy_appeals
    Api::V3::LegacyAppealSerializer.new(legacy_appeals, is_collection: true).serializable_hash
  end
end
