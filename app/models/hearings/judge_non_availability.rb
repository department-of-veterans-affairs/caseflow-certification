class JudgeNonAvailability < NonAvailability
  class << self
    def import_judge_non_availability(schedule_period)
      dates = HearingSchedule::GetSpreadsheetData.new(schedule_period.spreadsheet).judge_non_availability_data
      judge_non_availability = []
      transaction do
        dates.each do |date|
          css_id = UserRepository.css_id_by_vlj_id(date["vlj_id"])
          judge_non_availability << JudgeNonAvailability.create!(schedule_period: schedule_period,
                                                                 date: date["date"],
                                                                 object_identifier: css_id)
        end
      end
      judge_non_availability
    end
  end
end
