# frozen_string_literal: true

class VirtualHearingRepository
  class << self
    def ready_for_deletion
      virtual_hearings_for_ama_hearings = VirtualHearing.eligible_for_deletion
        .where(hearing_type: Hearing.name)
        .joins("INNER JOIN hearings ON hearings.id = virtual_hearings.hearing_id")
        .joins("INNER JOIN hearing_days ON hearing_days.id = hearings.hearing_day_id")
        .where("hearing_days.scheduled_for < :today", today: Time.zone.today)

      virtual_hearings_for_legacy_hearings = VirtualHearing.eligible_for_deletion
        .where(hearing_type: LegacyHearing.name)
        .joins("INNER JOIN legacy_hearings ON legacy_hearings.id = virtual_hearings.hearing_id")
        .joins("INNER JOIN hearing_days ON hearing_days.id = legacy_hearings.hearing_day_id")
        .where("hearing_days.scheduled_for < :today", today: Time.zone.today)

      virtual_hearings_for_ama_hearings + virtual_hearings_for_legacy_hearings
    end
  end
end
