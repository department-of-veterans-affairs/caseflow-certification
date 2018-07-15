describe SchedulePeriod do
  let(:schedule_period) { create(:ro_schedule_period) }
  let(:allocation) do
    create(:allocation, regional_office: "RO17", allocated_days: 118, schedule_period: schedule_period)
  end
  before do
    get_unique_dates_for_ro_between("RO17", schedule_period, 35)
    get_unique_dates_between(schedule_period.start_date, schedule_period.end_date, 20).map do |date|
      create(:co_non_availability, date: date, schedule_period_id: schedule_period.id)
    end
  end

  context "spreadsheet" do
    before do
      S3Service.store_file(schedule_period.file_name, "spec/support/validRoSpreadsheet.xlsx", :filepath)
    end

    subject { schedule_period.spreadsheet }

    it { is_expected.to be_a(Roo::Excelx) }
  end

  context "generate hearing schedule" do
    it do
      expect(schedule_period.ro_hearing_day_allocations.count).to eq(allocation.allocated_days)
    end
  end
end
