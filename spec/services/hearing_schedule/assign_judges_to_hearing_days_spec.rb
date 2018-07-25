describe HearingSchedule::AssignJudgesToHearingDays do
  let(:schedule_period) do
    create(:ro_schedule_period, start_date: Date.parse("2018-04-01"),
                                end_date: Date.parse("2018-07-31"))
  end

  let(:assign_judges_to_hearing_days) do
    HearingSchedule::AssignJudgesToHearingDays.new(schedule_period)
  end

  context "assign judges info from VACOLS staff and Caseflow" do
    subject { assign_judges_to_hearing_days }

    context "when Judge exists in both VACOLS and Caseflow" do
      before do
        3.times do
          judge = FactoryBot.create(:user)
          create(:staff, :hearing_judge, sdomainid: judge.css_id)
        end
      end

      it "Caseflow user and staff information are populated" do
        expect(subject.judges.count).to eq(3)
        subject.judges.each_key do |css_id|
          expect(subject.judges[css_id][:staff_info].sdomainid).to eq(css_id)
          expect(subject.judges[css_id][:user_info].css_id).to eq(css_id)
        end
      end
    end

    context "when judge exists in VACOLS but not caseflow" do
      before do
        3.times do |i|
          create(:staff, :hearing_judge, sdomainid: "CSS_ID_#{i}")
        end
      end

      it "staff info is populate but user info is nil" do
        expect(subject.judges.count).to eq(3)
        subject.judges.each_key do |css_id|
          expect(subject.judges[css_id][:staff_info].sdomainid).to eq(css_id)
          expect(subject.judges[css_id][:user_info]).to eq(nil)
        end
      end
    end
  end

  context "assigning non-available days to judges" do
    before do
      @num_non_available_days = [10, 5, 15]
      @num_non_available_days.count.times do |i|
        judge = FactoryBot.create(:user)
        get_unique_dates_between(schedule_period.start_date, schedule_period.end_date,
                                 @num_non_available_days[i]).map do |date|
          create(:judge_non_availability, object_identifier: judge.css_id,
                                          date: date, schedule_period_id: schedule_period.id)
        end
        create(:staff, :hearing_judge, sdomainid: judge.css_id)
      end
    end

    let(:assign_judges_to_hearing_days) do
      HearingSchedule::AssignJudgesToHearingDays.new(schedule_period)
    end

    subject { assign_judges_to_hearing_days }

    it "assigns non availabilities to judges" do
      expect(subject.judges.count).to eq(3)
      subject.judges.keys.each_with_index do |css_id, index|
        expect(subject.judges[css_id][:non_availabilities].count).to eq(@num_non_available_days[index])
      end
    end
  end

  context "handle travel board hearings" do
    let(:member1) { create(:staff, :hearing_judge) }
    let(:member2) { create(:staff, :hearing_judge) }
    let(:member3) { create(:staff, :hearing_judge) }

    let(:tb_hearing) do
      create(:travel_board_schedule, tbro: "RO17",
                                     tbstdate: Date.parse("2018-06-04"), tbenddate: Date.parse("2018-06-08"),
                                     tbmem1: member1.sattyid,
                                     tbmem2: member2.sattyid,
                                     tbmem3: member3.sattyid)
    end

    let(:tb_hearing2) do
      create(:travel_board_schedule, tbro: "RO17",
                                     tbstdate: Date.parse("2018-09-03"), tbenddate: Date.parse("2018-09-07"),
                                     tbmem1: member1.sattyid,
                                     tbmem2: member2.sattyid,
                                     tbmem3: member3.sattyid)
    end

    subject { assign_judges_to_hearing_days }

    it "judges are given non-availabilities based on travel board" do
      start_date = 3.business_days.before(tb_hearing[:tbstdate])
      end_date = 3.business_days.after(tb_hearing[:tbenddate])

      start_date2 = 3.business_days.before(tb_hearing2[:tbstdate])
      end_date2 = 3.business_days.after(tb_hearing2[:tbenddate])

      subject.judges do |_css_id, judge|
        expect(judge[:non_availabilities].include?(start_date)).to be_truthy
        expect(judge[:non_availabilities].include?(end_date)).to be_truthy

        expect(judge[:non_availabilities].include?(start_date2)).to be_truthy
        expect(judge[:non_availabilities].include?(end_date2)).to be_truthy
        expect(judge[:non_availabilities].count).to eq(22)
      end
    end
  end

  context "handle VIDEO hearings" do
    before do
      @judges = []
      video_hearing_days

      5.times do
        judge = FactoryBot.create(:user)
        @judges << create(:staff, :hearing_judge, sdomainid: judge.css_id)
      end
    end

    let(:video_hearing_days) do
      get_unique_dates_between(schedule_period.start_date, schedule_period.end_date, 10).map do |date|
        create(:case_hearing, hearing_type: "C", hearing_date: date, folder_nr: "VIDEO RO13")
      end
    end

    subject { assign_judges_to_hearing_days.match_hearing_days_to_judges }

    it "allocates VIDEO hearing days to judges" do
      # binding.pry
      expect(subject.count).to eq(video_hearing_days.count)
      judge_ids = subject.map { |hearing_day| hearing_day[:judge_id] }

      @judges.each do |judge|
        expect(judge_ids.count(judge.sattyid)).to eq(2)
      end
    end
  end

  context "handle co hearings" do
    before do
      co_hearing_days
    end

    let(:co_hearing_days) do
      get_unique_dates_between(schedule_period.start_date, schedule_period.end_date, 50).map do |date|
        create(:case_hearing, hearing_type: "C", hearing_date: date, folder_nr: nil)
      end
    end

    subject { assign_judges_to_hearing_days.video_co_hearing_days }

    it "filter CO non wednesdays" do
      subject.each do |hearing_day|
        expect(hearing_day.hearing_date.wednesday?).to be(true)
      end
    end
  end

  context "handle CO hearings" do
    before do
      co_hearing_days
    end

    let(:co_hearing_days) do
      get_unique_dates_between(schedule_period.start_date, schedule_period.end_date, 50).map do |date|
        create(:case_hearing, hearing_type: "C", hearing_date: date, folder_nr: nil)
      end
    end

    subject { assign_judges_to_hearing_days.video_co_hearing_days }

    it "filter CO non wednesdays" do
      subject.each do |hearing_day|
        expect(hearing_day.hearing_date.wednesday?).to be(true)
      end
    end
  end

  context "handle already assgined hearing day" do
    before do
      judge
      co_hearing_day
    end

    let(:judge) do
      judge = FactoryBot.create(:user)
      create(:staff, :hearing_judge, sdomainid: judge.css_id)
    end

    let(:co_hearing_day) do
      create(:case_hearing, hearing_type: "C", hearing_date: "2018-04-10",
                            board_member: judge.sattyid, folder_nr: "VIDEO RO13")
    end

    subject { assign_judges_to_hearing_days }

    it "expect judge to have non-available day" do
      expect(subject.judges[judge.sdomainid][:non_availabilities].include?(co_hearing_day.hearing_date)).to be(true)
    end
  end

  context "Allocating VIDEO and CO hearing days to judges evenly" do
    before do
      judges
      hearing_days

      create(:travel_board_schedule, tbro: "RO13",
                                     tbstdate: Date.parse("2018-06-04"), tbenddate: Date.parse("2018-06-08"),
                                     tbmem1: judges[0].sattyid,
                                     tbmem2: judges[1].sattyid,
                                     tbmem3: judges[2].sattyid)

      create(:travel_board_schedule, tbro: "RO13",
                                     tbstdate: Date.parse("2018-04-16"), tbenddate: Date.parse("2018-04-20"),
                                     tbmem1: judges[3].sattyid,
                                     tbmem2: judges[4].sattyid,
                                     tbmem3: judges[5].sattyid)
    end

    let(:judges) do
      judges = []
      7.times do
        judge = FactoryBot.create(:user)
        get_unique_dates_between(schedule_period.start_date, schedule_period.end_date,
                                 Random.rand(20..40)).map do |date|
          create(:judge_non_availability, date: date, schedule_period_id: schedule_period.id,
                                          object_identifier: judge.css_id)
        end
        judges << create(:staff, :hearing_judge, sdomainid: judge.css_id)
      end
      judges
    end

    let(:hearing_days) do
      @hearing_counter = 0
      hearing_days = {}
      get_dates_between(schedule_period.start_date, schedule_period.end_date, 60).map do |date|
        @hearing_counter += date.wednesday? ? 2 : 1
        case_hearing = create(:case_hearing, hearing_type: "C", hearing_date: date, folder_nr: "VIDEO RO13")
        hearing_days[case_hearing.hearing_pkseq] = case_hearing

        co_case_hearing = create(:case_hearing, hearing_type: "C", hearing_date: date, folder_nr: nil)
        hearing_days[co_case_hearing.hearing_pkseq] = co_case_hearing
      end
      hearing_days
    end

    subject { assign_judges_to_hearing_days }

    context "allocated judges to hearing days" do
      subject { assign_judges_to_hearing_days.match_hearing_days_to_judges }

      it "all hearing days should be assigned to judges" do
        expect(subject.count).to eq(@hearing_counter)
        judge_count = {}
        subject.each do |hearing_day|
          expected_day = hearing_days[hearing_day[:hearing_pkseq]]
          is_co = expected_day.folder_nr.nil?
          judge_count[hearing_day[:judge_id]] ||= 0
          judge_count[hearing_day[:judge_id]] += 1

          type = is_co ? HearingDay::HEARING_TYPES[:central] : HearingDay::HEARING_TYPES[:video]
          ro = is_co ? nil : expected_day.folder_nr.split(" ")[1]

          expect(expected_day).to_not be_nil
          expect(hearing_day[:hearing_type]).to eq(type)
          expect(hearing_day[:hearing_date]).to eq(expected_day.hearing_date)
          expect(hearing_day[:room_info]).to eq(expected_day.room)
          expect(hearing_day[:regional_office]).to eq(ro)
          expect(hearing_day[:judge_id]).to_not be_nil
          expect(hearing_day[:judge_name]).to_not be_nil
        end
      end
    end
  end
end
