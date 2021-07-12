# frozen_string_literal: true

class Api::V3::LegacyAppealSerializer
  include FastJsonapi::ObjectSerializer
  extend Helpers::AppealHearingHelper

  set_key_transform :camel_lower

  attribute :assigned_attorney
  attribute :assigned_judge

  attribute :hearing_request_type, &:readable_current_hearing_request_type

  attribute :original_hearing_request_type, &:readable_original_hearing_request_type

  attribute :issues do |object|
    object.issues.map do |issue|
      Api::V3::LegacyIssueSerializer.new(issue).serializable_hash[:data][:attributes]
    end
  end

  attribute :hearings do |object|
    object.hearings.map do |hearing|
      Api::V3::AppealHearingSerializer.new(hearing).serializable_hash[:data][:attributes]
    end
  end

  attribute :completed_hearing_on_previous_appeal?

  attribute :appellant_is_not_veteran, &:appellant_is_not_veteran

  attribute :appellant_full_name, &:appellant_name
  attribute :appellant_relationship
  attribute :veteran_full_name
  # Aliasing the vbms_id to make it clear what we're returning.
  attribute :veteran_file_number, &:sanitized_vbms_id
  attribute :type # need to find out what this is and if we want it
  attribute :aod
  attribute :docket_number
  attribute :status
  attribute :decision_date
  attribute :form9_date
  attribute :nod_date
  attribute :certification_date
  attribute :soc_date
  attribute :docket_name do
    "legacy"
  end
end
