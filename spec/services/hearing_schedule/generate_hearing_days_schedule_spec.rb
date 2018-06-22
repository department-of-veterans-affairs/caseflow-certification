describe HearingSchedule::GenerateHearingDaysSchedule do
  let(:schedule_period) { create(:ro_schedule_period) }

  let(:co_non_available_days) do
    get_unique_dates_between(schedule_period.start_date, schedule_period.end_date, 15).map do |date|
      create(:co_non_availability, date: date, schedule_period_id: schedule_period.id)
    end
  end

  let(:ro_one_non_available_days) do
    get_unique_dates_between(schedule_period.start_date, schedule_period.end_date, 8).map do |date|
      create(:ro_non_availability, date: date, schedule_period_id: schedule_period.id, object_identifier: "RO01")
    end
  end

  let(:ro_three_non_available_days) do
    get_unique_dates_between(schedule_period.start_date, schedule_period.end_date, 11).map do |date|
      create(:ro_non_availability, date: date, schedule_period_id: schedule_period.id, object_identifier: "RO03")
    end
  end

  let(:ro_allocations) do
    [
      create(:allocation, regional_office: "RO17", allocated_days: 118, schedule_period: schedule_period),
      create(:allocation, regional_office: "RO61", allocated_days: 66, schedule_period: schedule_period),
      create(:allocation, regional_office: "RO18", allocated_days: 61, schedule_period: schedule_period),
      create(:allocation, regional_office: "RO22", allocated_days: 55, schedule_period: schedule_period),
      create(:allocation, regional_office: "RO01", allocated_days: 24, schedule_period: schedule_period),
      create(:allocation, regional_office: "RO55", allocated_days: 6, schedule_period: schedule_period),
      create(:allocation, regional_office: "RO02", allocated_days: 3, schedule_period: schedule_period)
    ]
  end

  let(:ro_non_available_days) do
    {
      "RO01" => ro_one_non_available_days,
      "RO03" => ro_three_non_available_days
    }
  end

  let(:generate_hearing_days_schedule) do
    HearingSchedule::GenerateHearingDaysSchedule.new(
      schedule_period,
      co_non_available_days
    )
  end

  context "gets all available business days between a date range" do
    subject { generate_hearing_days_schedule.available_days }

    it "has available hearing days" do
      # total 130 weekdays - (15 N/A days + 3 holidays) = 112
      expect(subject.count).to be 112
    end

    it "removes weekends" do
      expect(subject.find { |day| day.saturday? || day.sunday? }).to eq nil
    end

    it "removes board non-available days" do
      expect(subject.find { |day| co_non_available_days.include?(day) }).to eq nil
    end
  end

  context "change the year" do
    # generating a schedule for 2025
    let(:generate_hearing_days_schedule) do
      HearingSchedule::GenerateHearingDaysSchedule.new(
        schedule_period,
        co_non_available_days.map do |day|
          day.date += 7.years
          day
        end
      )
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
      expect(subject.find { |day| federal_holidays.include?(day) }).to eq nil
    end
  end

  context "filter available days" do
    let(:generate_hearing_days_schedule_removed_ro_na) do
      HearingSchedule::GenerateHearingDaysSchedule.new(
        schedule_period,
        co_non_available_days,
        ro_non_available_days
      )
    end

    context "RO available days" do
      subject { generate_hearing_days_schedule_removed_ro_na }

      it "assigns ros to initial available days" do
        subject.ros.map { |key, _value| expect(subject.ros[key][:available_days]).to eq subject.available_days }
      end

      it "remove non-available_days" do
        subject.ros.each do |key, value|
          includes_ro_days = value[:available_days].map do |date|
            (ro_non_available_days[key] || []).include?(date)
          end

          expect(includes_ro_days.any?).to eq false
        end
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
    before do
      ro_allocations
    end

    let(:generate_hearing_days_schedule) do
      HearingSchedule::GenerateHearingDaysSchedule.new(
        schedule_period,
        co_non_available_days,
        ro_non_available_days
      )
    end

    it "travel board hearing days removed" do
      generate_hearing_days_schedule
      # binding.pry
    end
  end
end
