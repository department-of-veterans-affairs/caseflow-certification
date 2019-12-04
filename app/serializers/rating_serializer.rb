# frozen_string_literal: true

class RatingSerializer
  include FastJsonapi::ObjectSerializer
  set_id(&:participant_id)

  attribute :participant_id
  attribute :profile_date
  attribute :promulgation_date
  attribute :issues do |object|
    object.issues.map(&:serialize)
  end

  attribute :decisions do |object|
    object.decisions.map(&:serialize)
  end
end
