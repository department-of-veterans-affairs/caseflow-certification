# frozen_string_literal: true

module Helpers::AppealHearingHelper
  def available_hearing_locations(appeal)
    locations = appeal.available_hearing_locations || []

    locations.map do |ahl|
      ahl.to_hash
    end
  end

  def hearings(appeal)
    appeal.hearings.map do |hearing|
      AppealHearingSerializer.new(hearing).serializable_hash[:data][:attributes]
    end
  end

  def suggested_hearing_location(appeal)
    appeal.suggested_hearing_location.to_hash
  end
end
