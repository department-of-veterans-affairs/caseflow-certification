class RoSchedulePeriod < SchedulePeriod
  validate :validate_spreadsheet, on: :create
  after_create :import_spreadsheet

  cache_attribute :algorithm_assignments, expires_in: 4.days do
    genenerate_ro_hearing_schedule
  end

  def validate_spreadsheet
    validate_spreadsheet = HearingSchedule::ValidateRoSpreadsheet.new(spreadsheet, start_date, end_date)
    errors[:base] << validate_spreadsheet.validate
  end

  def import_spreadsheet
    RoNonAvailability.import_ro_non_availability(self)
    CoNonAvailability.import_co_non_availability(self)
    Allocation.import_allocation(self)
  end

  def schedule_confirmed(hearing_schedule)
    HearingDay.create_schedule(hearing_schedule)
    super
  end

  private

  def format_ro_data(ro_allocations)
    ro_allocations.reduce([]) do |acc, (ro_key, ro_info)|
      ro_info[:allocated_dates].each_value do |dates|
        dates.each do |date, rooms|
          rooms.each do |room|
            acc << HearingDayMapper.hearing_day_field_validations(
              hearing_type: :video,
              hearing_date: date,
              room_info: room[:room_num],
              regional_office: ro_key
            )
          end
        end
      end
      acc
    end
  end

  def genenerate_ro_hearing_schedule
    generate_hearings_days = HearingSchedule::GenerateHearingDaysSchedule.new(self)
    format_ro_data(generate_hearings_days.allocate_hearing_days_to_ros)
  end
end
