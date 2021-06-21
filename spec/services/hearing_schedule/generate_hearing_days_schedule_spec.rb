# frozen_string_literal: true

describe HearingSchedule::GenerateHearingDaysSchedule, :all_dbs do
  let(:schedule_period) do
    create(:blank_ro_schedule_period, start_date: Date.parse("2018-04-01"),
                                      end_date: Date.parse("2018-09-30"))
  end

  let(:generate_hearing_days_schedule) do
    HearingSchedule::GenerateHearingDaysSchedule.new(schedule_period)
  end

  context "gets all available business days between a date range" do
    let!(:co_non_availability_days) do
      get_unique_dates_between(schedule_period.start_date, schedule_period.end_date, 15).map do |date|
        create(:co_non_availability, date: date, schedule_period_id: schedule_period.id)
      end
    end

    subject { generate_hearing_days_schedule.available_days }

    it "has available hearing days" do
      # total 130 weekdays - (15 N/A days + 3 holidays) = 112
      expect(subject.count).to be 112
    end

    it "removes weekends" do
      expect(subject.find { |day| day.saturday? || day.sunday? }).to eq nil
    end

    it "removes board non-available days" do
      expect(subject.find { |day| co_non_availability_days.include?(day) }).to eq nil
    end
  end

  context "change the year" do
    before do
      get_unique_dates_between(schedule_period.start_date, schedule_period.end_date, 25).map do |date|
        create(:co_non_availability, date: date, schedule_period_id: schedule_period.id)
      end
    end

    let(:schedule_period) do
      create(:blank_ro_schedule_period, start_date: Date.parse("2025-01-01"),
                                        end_date: Date.parse("2025-12-31"))
    end

    # generating a schedule for 2025
    let(:generate_hearing_days_schedule) do
      HearingSchedule::GenerateHearingDaysSchedule.new(schedule_period)
    end

    let(:federal_holidays) do
      [
        Date.parse("2025-01-01"),
        Date.parse("2025-01-20"),
        Date.parse("2025-02-17"),
        Date.parse("2025-05-26"),
        Date.parse("2025-07-04"),
        Date.parse("2025-09-01"),
        Date.parse("2025-10-13"),
        Date.parse("2025-11-11"),
        Date.parse("2025-11-27"),
        Date.parse("2025-12-25")
      ]
    end

    subject { generate_hearing_days_schedule.available_days }

    it "removes holidays" do
      expect(federal_holidays.find { |day| subject.include?(day) }).to eq nil
    end
  end

  context "filter available days" do
    let(:generate_hearing_days_schedule_removed_ro_na) do
      HearingSchedule::GenerateHearingDaysSchedule.new(schedule_period)
    end

    context "RO available days" do
      let(:ro_non_availability_days) do
        {
          "RO17" => get_unique_dates_for_ro_between("RO17", schedule_period, 25),
          "RO61" => get_unique_dates_for_ro_between("RO61", schedule_period, 15),
          "RO18" => get_unique_dates_for_ro_between("RO18", schedule_period, 10),
          "RO22" => get_unique_dates_for_ro_between("RO22", schedule_period, 18),
          "RO01" => get_unique_dates_for_ro_between("RO01", schedule_period, 20),
          "RO55" => get_unique_dates_for_ro_between("RO55", schedule_period, 25),
          "RO02" => get_unique_dates_for_ro_between("RO02", schedule_period, 20),
          "RO21" => get_unique_dates_for_ro_between("RO21", schedule_period, 100),
          "RO27" => get_unique_dates_for_ro_between("RO27", schedule_period, 0),
          "RO28" => get_unique_dates_for_ro_between("RO28", schedule_period, 40)
        }
      end
      subject { generate_hearing_days_schedule_removed_ro_na }

      it "assigns ros to initial available days" do
        subject.ros.map { |key, _value| expect(subject.ros[key][:available_days]).to eq subject.available_days }
      end

      it "remove non-available_days" do
        subject.ros.each do |key, value|
          includes_ro_days = value[:available_days].map do |date|
            (ro_non_availability_days[key] || []).include?(date)
          end

          expect(includes_ro_days.any?).to eq false
        end
      end
    end

    context "RO-non availability days not provided" do
      subject { generate_hearing_days_schedule_removed_ro_na }

      it "throws an ro non-availability days not provided" do
        expect(subject.ros.count).to eq schedule_period.allocations.count
      end
    end

    context "Travelboard hearing days" do
      let(:travel_board_schedules) do
        [
          create(:travel_board_schedule),
          create(:travel_board_schedule, tbro: "RO17",
                                         tbstdate: Date.parse("2018-06-04"), tbenddate: Date.parse("2018-06-08")),
          create(:travel_board_schedule, tbro: "RO17",
                                         tbstdate: Date.parse("2018-07-09"), tbenddate: Date.parse("2018-07-13")),
          create(:travel_board_schedule, tbro: "RO18",
                                         tbstdate: Date.parse("2018-08-27"), tbenddate: Date.parse("2018-08-31")),
          create(:travel_board_schedule, tbro: "RO01",
                                         tbstdate: Date.parse("2018-04-23"), tbenddate: Date.parse("2018-04-27")),
          create(:travel_board_schedule, tbro: "RO55",
                                         tbstdate: Date.parse("2018-04-09"), tbenddate: Date.parse("2018-04-13")),
          create(:travel_board_schedule, tbro: "RO22",
                                         tbstdate: Date.parse("2018-05-14"), tbenddate: Date.parse("2018-05-18")),
          create(:travel_board_schedule, tbro: "RO02",
                                         tbstdate: Date.parse("2018-05-14"), tbenddate: Date.parse("2018-05-18")),
          create(:travel_board_schedule, tbro: "RO02",
                                         tbstdate: Date.parse("2018-05-21"), tbenddate: Date.parse("2018-05-25")),
          create(:travel_board_schedule, tbro: "RO27",
                                         tbstdate: Date.parse("2018-05-21"), tbenddate: Date.parse("2018-05-25")),
          create(:travel_board_schedule, tbro: "RO27",
                                         tbstdate: Date.parse("2018-05-21"), tbenddate: Date.parse("2018-05-25"))
        ]
      end

      let(:generate_hearing_days_schedule_removed_tb) do
        HearingSchedule::GenerateHearingDaysSchedule.new(
          schedule_period
        )
      end

      subject { generate_hearing_days_schedule_removed_tb }

      it "travel board hearing days removed" do
        travel_board_schedules.each do |tb_schedule|
          dates = (tb_schedule[:tbstdate]..tb_schedule[:tbenddate]).to_a
          expect(dates.map { |date| subject.ros[tb_schedule[:tbro]][:available_days].include?(date) }.any?).to eq false
        end
      end
    end
  end

  context "RO hearing days allocation" do
    let(:ro_schedule_period) { create(:ro_schedule_period) }

    let(:generate_hearing_days_schedule) do
      HearingSchedule::GenerateHearingDaysSchedule.new(ro_schedule_period)
    end

    context "with invalid request data" do
      let(:generate_invalid_hearing_days_schedule) do
        HearingSchedule::GenerateHearingDaysSchedule.new(schedule_period)
      end

      subject do
        generate_invalid_hearing_days_schedule.allocate_hearing_days_to_ros
        generate_hearing_days_schedule.allocation_result
      end

      context "too many ro non-availability days" do
        let!(:ro_non_availability_days) do
          {
            "RO17" => get_unique_dates_for_ro_between("RO17", schedule_period, 127)
          }
        end
        let!(:ro_allocations) do
          [
            create(:allocation, regional_office: "RO17", allocated_days: 1, schedule_period: schedule_period)
          ]
        end

        it {
          expect { subject }.to raise_error(HearingSchedule::GenerateHearingDaysSchedule::NoDaysAvailableForRO)
        }
      end

      context "too many co non-availability days" do
        let!(:co_non_availability_days) do
          get_unique_dates_between(schedule_period.start_date, schedule_period.end_date, 127).map do |date|
            create(:co_non_availability, date: date, schedule_period_id: schedule_period.id)
          end
        end

        let!(:ro_allocations) do
          [
            create(:allocation, regional_office: "RO17", allocated_days: 1, schedule_period: schedule_period)
          ]
        end

        it { expect { subject }.to raise_error(HearingSchedule::GenerateHearingDaysSchedule::NoDaysAvailableForRO) }
      end
    end

    context "video hearing days" do
      subject do
        generate_hearing_days_schedule.allocate_hearing_days_to_ros
        generate_hearing_days_schedule.allocation_results
      end

      it "assigns hearing days" do
        allocations = ro_schedule_period.allocations.reduce({}) do |acc, ro|
          acc[ro.regional_office] = ro.allocated_days
          acc
        end

        # Calculate how many assignments were made
        total_assignments = subject.reduce(0) do |acc, (_k, v)|
          acc += v[:allocated_dates].values.map(&:values).flatten.count
          acc
        end

        # Ensure there are the correct number of allocations for each RO
        expect(subject.keys.sort).to eq(allocations.keys.sort)

        # Ensure that only video days were allocated
        expect(total_assignments).to eq(allocations.values.sum.to_i)
      end
    end

    context "virtual hearing days" do
      subject do
        generate_hearing_days_schedule.allocate_hearing_days_to_ros(:allocated_days_without_room)
        generate_hearing_days_schedule.allocation_results
      end

      context "allocated days to ros" do
        it "allocates hearing days based on allocated_days_without_room" do
          # Reduce the schedule period allocations into the allocated roomless days
          allocations = ro_schedule_period.allocations.reduce({}) do |acc, ro|
            acc[ro.regional_office] = ro.allocated_days_without_room
            acc
          end

          # Calculate how many assignments were made
          total_assignments = subject.reduce(0) do |acc, (_k, v)|
            acc += v[:allocated_dates].values.map(&:values).flatten.count
            acc
          end

          # Ensure there are the correct number of allocations for each RO
          expect(subject.keys.sort).to eq(allocations.keys.sort)

          # Ensure that only virtual days were allocated
          expect(total_assignments).to eq(allocations.values.sum.to_i)

          subject.each_key do |ro_key|
            # Collect the assigned dates for this RO
            dates = subject[ro_key][:allocated_dates].reduce({}) do |acc, (k, v)|
              acc[k] = acc[k] || 0
              acc[k] += v.values.map(&:size).inject(:+)
              acc
            end

            # Ensure that the requested dates per RO were assigned
            expect(dates.values.sum).to eq(allocations[ro_key].ceil)
          end
        end
      end
    end

    context "allocated days to Central Office" do
      subject { generate_hearing_days_schedule.generate_co_hearing_days_schedule }

      it "only allocates 1 docket per week" do
        # 22 wednesdays between 2018-01-01 and 2018-06-30; due to holidays
        # it picks another day
        expect(subject.count).to eq(22)
      end
    end

    # Travel board days don't have hearing days they are blackout dates
    # TODO remove this after refactor
    # rubocop:disable all
    context "combined allocation (video, virtual, central)" do
      # Take a list of hearing_days and condense them per ro, date, and type,
      # results look like this.
      # {"RO39" => {
      #   "day_counts" => {
      #     "08-18-2021" => {
      #       "video" => 12,
      #       "virtual" => 41,
      #       "central" => 1}
      #     }
      #   }
      # }
      def condense_hearing_days(hearing_days)
        # Generate day_counts for each date/type from the hearing_days
        day_counts = {}
        hearing_days.each do |hearing_day|
          # Extract the keys we will use to create nested hashes
          scheduled_for = hearing_day[:scheduled_for]
          type = hearing_day[:request_type]
          # Deal with central hearings by creating "C" as an RO (which it's not really)
          ro = (hearing_day[:request_type] == "C") ? "C" : hearing_day[:regional_office]

          # Create the hashes/keys if they don't exist
          day_counts[ro] = {} unless day_counts.key?(ro)
          day_counts[ro][scheduled_for] = {} unless day_counts[ro].key?(scheduled_for)
          day_counts[ro][scheduled_for][type] = 0 unless day_counts[ro][scheduled_for].key?(type)

          # Update the count for this ro, date, type combo
          day_counts[ro][scheduled_for][type] += 1
        end
        day_counts
      end

      # If count < min then update min, if count > max update max
      # If max is nil, set it to count
      # if min is nil, set it to count
      def update_min_max(count, current_min, current_max)
        # If count is nil, update nothing.
        if count.nil?
          return [current_min, current_max]
        end
        # If current min or max are nil, set them to count
        if current_min.nil?
          current_min = count
        end
        if current_max.nil?
          current_max = count
        end

        # Compare count and new min/max, return appropriate value
        new_min = count < current_min ? count : current_min
        new_max = count > current_max ? count : current_max

        return [new_min, new_max]
      end

      def update_total_min_max(count, current_total, current_min, current_max)
        current_total = 0 if current_total.nil?
        new_total = count.present? ? current_total + count : current_total

        new_min, new_max = update_min_max(count, current_min, current_max)

        [new_min, new_max, new_total]
      end

      # Take the condensed list of hearing_days and generate summary statistics
      # Some summary stats are per date, some are for every date the ro has
      # {"RO39" => {
      #   "summary" => {
      #     # Video days
      #     "avg_V" => "2",
      #     "min_V" => "2",
      #     "max_V" => "2",
      #
      #     # Virtual days
      #     "avg_R" => "6",
      #     "min_R" => "1",
      #     "max_R" => "14",
      #   },
      def summarize_condensed_hearing_days(condensed_hearing_days)
        condensed_hearing_days.each do |ro, hearing_days|
          summary = {}
          types = ["R", "V", "C"]
          summary["date_total"] = {}

          # Each type of hearing
          types.each do |type|
            counts_label = "counts_#{type}"
            summary[counts_label] = []

            # Each date that has hearing_days
            hearing_days.each do |date, types|
              count = types[type]
              next if count.nil?

              # For each ro, update min and max days per date
              min_label = "min_#{type}"
              max_label = "max_#{type}"
              new_min, new_max = update_min_max(count, summary[min_label], summary[max_label])
              summary[min_label] = new_min
              summary[max_label] = new_max

              # Store the count for later per_ro_summarization
              summary[counts_label].push(count)

              # Across all ros
              new_all_ro_min, new_all_ro_max, new_all_ro_total = update_total_min_max(
                count,
                summary["date_total"][date],
                summary["min_days_on_any_date"],
                summary["max_days_on_any_date"]
              )
              summary["min_days_on_any_date"] = new_all_ro_min
              summary["max_days_on_any_date"] = new_all_ro_max
              summary["date_total"][date] = new_all_ro_total
            end

            # Take the array of hearing_day_counts per type and generate summary stats
            # per_ro_summary_stats(hearing_day_counts)
            if summary[counts_label].count > 0
              total_label = "total_#{type}"
              total = summary[counts_label].size
              summary[total_label] = total

              sum_label = "sum_#{type}"
              sum = summary[counts_label].sum(0.0)
              summary[sum_label] = sum

              avg_label = "avg_#{type}"
              average = sum / total
              summary[avg_label] = average
            end

            summary.delete(counts_label)
          end
          condensed_hearing_days[ro]["summary_statistics"] = summary
        end
        condensed_hearing_days
      end

      # These are the hearing days as displayed in the UI preview of the schedule
      #displayed_hearing_days = ro_schedule_period.algorithm_assignments
      # Create a summary of the data to make testing possible
      # {"RO39" => {
      #   "summary" => {
      #     "avg_video_days_per_date" => "2",
      #     "min_video_days_per_date" => "2",
      #     "max_video_days_per_date" => "2",
      #
      #     "avg_virtual_days_per_date" => "6",
      #     "min_virtual_days_per_date" => "1",
      #     "max_virtual_days_per_date" => "14",
      #   },
      #   "day_counts" => {
      #     "08-18-2021" => {
      #       "video" => 12,
      #       "virtual" => 41,
      #       "central" => 1}
      #     }
      #   }
      # }
      #summary_and_day_counts = format_hearing_days(displayed_hearing_days)

      let(:ro_schedule_period) { create(:real_ro_schedule_period) }
      let :day_counts_and_summary_per_ro do
        displayed_hearing_days = ro_schedule_period.algorithm_assignments
        condensed_hearing_days = condense_hearing_days(displayed_hearing_days)
        summarize_condensed_hearing_days(condensed_hearing_days)
      end

      it "allocates all days evenly across available dates for each ro" do
        # It's okay for different dates at the same RO to have this difference.
        # Something like this is NOT okay:
        #  - 10/24/2021: 10 hearing_days
        #  - 10/25/2021: 17 hearing_days
        day_counts_and_summary_per_ro.each do |ro_key, info|
          min_days_per_date = info["summary_statistics"]["min_days_on_any_date"]
          max_days_per_date = info["summary_statistics"]["max_days_on_any_date"]
          expect(max_days_per_date - min_days_per_date).to be <= 5
        end
      end

      it "allocates each type of days evenly across available dates for each ro" do
        day_counts_and_summary_per_ro.each do |ro_key, info|
          types = ["R", "V", "C"]
          types.each do |type|
            min_label = "min_#{type}"
            max_label = "max_#{type}"
            min = info["summary_statistics"][min_label]
            max = info["summary_statistics"][max_label]

            ro_has_days_of_type = max.present? || min.present?
            expect(max - min).to be <= 5 if ro_has_days_of_type
          end
        end
      end

      it "allocates central days exactly a week apart" do
        central_dates = day_counts_and_summary_per_ro["C"]["summary_statistics"]["date_total"].to_a
        central_dates.each_with_index do |current_date, index|
          # Dont compare the last date to 'nil', dont run off the end
          if index < central_dates.count - 2 
            next_date = central_dates[index + 1][0]
            expect(next_date).to eq(current_date[0].advance(days: 7))
          end
        end
      end
    end
  end
end
