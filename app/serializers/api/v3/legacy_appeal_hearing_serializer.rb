
# frozen_string_literal: true

class Api::V3::LegacyAppealHearingSerializer
  include FastJsonapi::ObjectSerializer

  attribute :date, &:scheduled_for
  attribute :disposition # "Hearing disposition; can be one of: 'held', 'postponed', 'no_show', or 'cancelled'"
  attribute :is_virtual, &:virtual?
  attribute :notes # "Any notes taken prior or post hearing"
  attribute :type, &:readable_request_type
  # this assumes only the assigned judge will view the hearing worksheet. otherwise,
  # we should check `hearing.hearing_views.map(&:user_id).include? judge.css_id`
  attribute :viewed_by_judge do |hearing|
    # !hearing.hearing_views.empty?
    any_views = !hearing.hearing_views.empty?
    any_judge_views = hearing.hearing_views.map(&:user_id).include?(judge.css_id) # this to resolve the above comment?

    any_views && any_judge_views
  end
  attribute :created_at
end
