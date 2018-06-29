# GenerateHearingDaysSchedule is used to generate the dates available for RO
# video hearings in a specified date range after filtering out weekends,
# holidays, and board non-availability dates
#

class HearingSchedule::GenerateHearingDaysSchedule
  include HearingSchedule::RoAllocation
  include HearingSchedule::RoDistribution

  class RoNonAvailableDaysNotProvided < StandardError; end

  attr_reader :available_days
  attr_reader :ros

  MULTIPLE_ROOM_ROS = %w[RO17 RO18].freeze
  MULTIPLE_NUM_OF_ROOMS = 2
  DEFAULT_NUM_OF_ROOMS = 1

  def initialize(schedule_period, co_non_availability_days = [], ro_non_available_days = {})
    @amortized = 0
    @co_non_availability_days = co_non_availability_days
    @schedule_period = schedule_period
    @holidays = Holidays.between(schedule_period.start_date, schedule_period.end_date, :federal_reserve)
    @available_days = filter_non_availability_days(schedule_period.start_date, schedule_period.end_date)
    @ro_non_available_days = ro_non_available_days

    # handle RO information
    assign_and_filter_ro_days(schedule_period)
  end

  def assign_and_filter_ro_days(schedule_period)
    @ros = assign_ro_hearing_day_allocations(RegionalOffice::CITIES, schedule_period.allocations)
    filter_non_available_ro_days
    @ros = filter_travel_board_hearing_days(schedule_period.start_date, schedule_period.end_date)
  end

  def filter_non_availability_days(start_date, end_date)
    business_days = []
    current_day = start_date

    while current_day <= end_date
      business_days << current_day unless
        weekend?(current_day) || holiday?(current_day) || co_not_available?(current_day)
      current_day += 1.day
    end

    business_days
  end

  def monthly_distributed_weights(monthly_weights, allocated_days)
    monthly_weights.map do |month, weight|
      [month, distribute(weight, allocated_days)]
    end.to_h
  end

  def add_allocated_days_and_format(grouped_shuffled_monthly_dates, ro_key)
    @ros[ro_key][:allocated_dates] = grouped_shuffled_monthly_dates.reduce({}) do |acc, (k, v)|
      acc[k] = v.to_a.sort.to_h
      acc
    end
  end

  def allocate_hearing_days_to_ros
    @amortized = 0

    monthly_percentages = self.class.montly_percentage_for_period(@schedule_period.start_date,
                                                                  @schedule_period.end_date)
    monthly_weights = self.class.weight_by_percentages(monthly_percentages)

    @ros.each_key do |ro_key|
      monthly_allocated_days = monthly_distributed_weights(monthly_weights, @ros[ro_key][:allocated_days])
      grouped_monthly_avail_dates = group_dates_by_month(@ros[ro_key][:available_days])

      ro_available_days = grouped_monthly_avail_dates.map { |k, v| [k, v.size] }.to_h
      num_of_rooms = @ros[ro_key][:num_of_rooms]

      monthly_allocations = self.class.get_monthly_allocations(
        grouped_monthly_avail_dates, ro_available_days, monthly_allocated_days, num_of_rooms
      )
      grouped_shuffled_monthly_dates = self.class.shuffle_grouped_monthly_dates(grouped_monthly_avail_dates)

      date_index = 0
      while monthly_allocations.values.inject(:+) != 0
        allocate_hearing_days_to_individual_ro(
          monthly_allocations, grouped_shuffled_monthly_dates, num_of_rooms, date_index
        )
        date_index += 1
      end
      add_allocated_days_and_format(grouped_shuffled_monthly_dates, ro_key)
    end

  end

  def allocate_hearing_days_to_individual_ro(monthly_allocations,
                                             grouped_shuffled_monthly_dates, num_of_rooms, date_index)
    monthly_allocations.each_key do |month|
      allocated_days = monthly_allocations[month]
      monthly_date_keys = grouped_shuffled_monthly_dates[month].keys

      if allocated_days > 0
        if num_of_rooms < allocated_days
          grouped_shuffled_monthly_dates[month][monthly_date_keys[date_index]] = num_of_rooms
            .times.map { |room_num| { room_num: room_num + 1 } }
          allocated_days -= num_of_rooms
        else
          grouped_shuffled_monthly_dates[month][monthly_date_keys[date_index]] = allocated_days
            .times.map { |room_num| { room_num: room_num + 1 } }
          allocated_days -= allocated_days
        end
      end

      monthly_allocations[month] = allocated_days
    end
  end

  private

  def group_dates_by_month(dates)
    dates.group_by { |d| [d.month, d.year] }
  end

  def distribute(percentage, total)
    real = (percentage * total) + @amortized
    natural = real.round
    @amortized = real - natural

    natural
  end

  def assign_ro_hearing_day_allocations(ro_cities, ro_allocations)
    ro_allocations.reduce({}) do |acc, allocation|
      acc[allocation.regional_office] = ro_cities[allocation.regional_office].merge(
        allocated_days: allocation.allocated_days,
        available_days: @available_days,
        num_of_rooms: MULTIPLE_ROOM_ROS.include?(allocation.regional_office) ? MULTIPLE_NUM_OF_ROOMS : DEFAULT_NUM_OF_ROOMS
      )
      acc
    end
  end

  def filter_travel_board_hearing_days(start_date, end_date)
    travel_board_hearing_days = VACOLS::TravelBoardSchedule.load_days_for_range(start_date, end_date)
    tb_master_records = TravelBoardScheduleMapper.convert_from_vacols_format(travel_board_hearing_days)

    tb_master_records.select { |tb_master_record| @ros.keys.include?(tb_master_record[:ro]) }
      .map do |tb_master_record|
        tb_days = (tb_master_record[:start_date]..tb_master_record[:end_date]).to_a
        @ros[tb_master_record[:ro]][:available_days] -= tb_days
      end
    @ros
  end

  def weekend?(day)
    day.saturday? || day.sunday?
  end

  def holiday?(day)
    @holidays.find { |holiday| holiday[:date] == day }.present?
  end

  def co_not_available?(day)
    @co_non_availability_days.find { |non_availability_day| non_availability_day.date == day }.present?
  end

  # Filters out the non-available RO days from the board available days for
  # each RO.
  #
  # This expects ro_non_available_days to be a hash
  # For example:
  #   {"RO15" => [
  #     Mon, 02 Apr 2018,
  #     Wed, 04 Apr 2018,
  #     Thu, 05 Apr 2018,
  #     Fri, 06 Apr 2018
  #   ]}
  #
  def filter_non_available_ro_days
    @ros.each_key do |ro_key|
      fail RoNonAvailableDaysNotProvided, "Non-availability days not provided for #{ro_key}" unless @ro_non_available_days[ro_key]
      @ros[ro_key][:available_days] -= (@ro_non_available_days[ro_key].map(&:date) || [])
    end
  end
end
