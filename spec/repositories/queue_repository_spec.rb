describe QueueRepository do
  before do
    FeatureToggle.enable!(:test_facols)
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  after do
    FeatureToggle.disable!(:test_facols)
    Timecop.return
  end

  context ".assign_case_to_attorney!" do
    before do
      RequestStore.store[:current_user] = judge
    end

    let(:judge) { User.create(css_id: "BAWS123", station_id: User::BOARD_STATION_ID) }
    let(:attorney) { User.create(css_id: "SAMD456", station_id: User::BOARD_STATION_ID) }
    let(:vacols_case) { create(:case, bfcurloc: judge_staff.slogid) }
    def vacols_id
      vacols_case.bfkey
    end

    let!(:judge_staff) do
      create(:staff, :judge_role, slogid: "BVABAWS", sdomainid: judge.css_id)
    end
    let!(:attorney_staff) do
      create(:staff, :attorney_role, stitle: "DF", slogid: "BVASAMD", sdomainid: attorney.css_id)
    end

    context "when vacols ID is valid" do
      it "should assign a case to attorney" do
        expect(vacols_case.bfcurloc).to eq judge_staff.slogid
        expect(VACOLS::Decass.where(defolder: vacols_case.bfkey).count).to eq 0

        QueueRepository.assign_case_to_attorney!(judge: judge, attorney: attorney, vacols_id: vacols_id)

        expect(vacols_case.reload.bfcurloc).to eq attorney_staff.slogid
        expect(vacols_case.bfattid).to eq attorney_staff.sattyid
        decass = VACOLS::Decass.where(defolder: vacols_case.bfkey).first
        expect(decass.present?).to eq true
        expect(decass.deatty).to eq attorney_staff.sattyid
        expect(decass.deteam).to eq attorney_staff.stitle[0..2]
        expect(decass.deadusr).to eq judge_staff.slogid
        expect(decass.deadtim).to eq VacolsHelper.local_date_with_utc_timezone
        expect(decass.dedeadline).to eq VacolsHelper.local_date_with_utc_timezone + 30.days
        expect(decass.deassign).to eq VacolsHelper.local_date_with_utc_timezone
      end
    end

    context "when vacols ID is not valid" do
      let(:vacols_id) { "09647474" }

      it "should raise ActiveRecord::RecordNotFound" do
        expect do
          QueueRepository.assign_case_to_attorney!(judge: judge, attorney: attorney, vacols_id: vacols_id)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the case has already been assigned to an attorney" do
      it "should throw an exception" do
        vacols_case.update(bfcurloc: attorney.vacols_uniq_id)

        expect do
          QueueRepository.assign_case_to_attorney!(judge: judge, attorney: attorney, vacols_id: vacols_id)
        end.to raise_error(Caseflow::Error::QueueRepositoryError)
      end
    end

    context "when the case already has a Decass record" do
      it "should throw an exception" do
        create(:decass, defolder: vacols_id)

        expect do
          QueueRepository.assign_case_to_attorney!(judge: judge, attorney: attorney, vacols_id: vacols_id)
        end.to raise_error(Caseflow::Error::QueueRepositoryError)
      end
    end
  end

  context ".reassign_case_to_judge!" do
    before do
      RequestStore.store[:current_user] = attorney
    end

    subject do
      QueueRepository.reassign_case_to_judge!(
        vacols_id: vacols_case.bfkey,
        created_in_vacols_date: date_added,
        judge_vacols_user_id: judge.vacols_uniq_id,
        decass_attrs: decass_attrs
      )
    end

    let(:decass_attrs) do
      {
        work_product: "Decision",
        overtime: false,
        note: "something",
        document_id: "123456789",
        modifying_user: attorney.vacols_uniq_id,
        reassigned_to_judge_date: VacolsHelper.local_date_with_utc_timezone
      }
    end

    let(:judge) { User.create(css_id: "BAWS123", station_id: User::BOARD_STATION_ID) }
    let(:attorney) { User.create(css_id: "FATR456", station_id: User::BOARD_STATION_ID) }
    let(:vacols_case) { create(:case, bfcurloc: attorney_staff.slogid) }
    let!(:judge_staff) do
      create(:staff, :judge_role, slogid: "BVABAWS", sdomainid: judge.css_id)
    end
    let!(:attorney_staff) do
      create(:staff, :attorney_role, slogid: "BVASAMD", sdomainid: attorney.css_id)
    end

    context "when decass record is found" do
      let(:date_added) { "2018-04-18".to_date }
      let!(:decass) { create(:decass, defolder: vacols_case.bfkey, deadtim: date_added) }

      it "should update decass record succesfully" do
        subject
        expect(decass.reload.deprod).to eq "DEC"
        expect(decass.dedocid).to eq "123456789"
        expect(decass.deatcom).to eq "something"
        expect(decass.demdusr).to eq attorney.vacols_uniq_id
        expect(decass.demdtim).to eq VacolsHelper.local_date_with_utc_timezone
        expect(decass.dereceive).to eq VacolsHelper.local_date_with_utc_timezone
        expect(vacols_case.reload.bfcurloc).to eq judge.vacols_uniq_id
      end
    end

    context "when vacols ID and date added are not valid" do
      let(:date_added) { "2018-04-18".to_date }
      let!(:decass) { create(:decass, defolder: vacols_case.bfkey, deadtim: "2014-04-18".to_date) }

      it "should raise Caseflow::Error::QueueRepositoryError" do
        expect { subject }.to raise_error(Caseflow::Error::QueueRepositoryError)
      end
    end
  end

  context ".reassign_case_to_attorney!" do
    before do
      RequestStore.store[:current_user] = judge
    end

    subject do
      QueueRepository.reassign_case_to_attorney!(
        judge: judge,
        attorney: attorney,
        vacols_id: vacols_case.bfkey,
        created_in_vacols_date: date_added
      )
    end

    let(:judge) { User.create(css_id: "BAWS123", station_id: User::BOARD_STATION_ID) }
    let(:attorney) { User.create(css_id: "FATR456", station_id: User::BOARD_STATION_ID) }
    let(:vacols_case) { create(:case, bfcurloc: judge_staff.slogid) }
    let!(:judge_staff) do
      create(:staff, :judge_role, slogid: "BVABAWS", sdomainid: judge.css_id)
    end
    let!(:attorney_staff) do
      create(:staff, :attorney_role, stitle: "DF", slogid: "BVASAMD", sdomainid: attorney.css_id)
    end

    context "when vacols ID and date added are valid" do
      let(:date_added) { "2018-04-18".to_date }
      let!(:decass) { create(:decass, defolder: vacols_case.bfkey, deadtim: date_added) }

      it "should assign a case to attorney" do
        expect(vacols_case.bfcurloc).to eq judge_staff.slogid
        expect(VACOLS::Decass.where(defolder: vacols_case.bfkey).count).to eq 1
        subject
        expect(vacols_case.reload.bfcurloc).to eq attorney_staff.slogid
        expect(vacols_case.bfattid).to eq attorney_staff.sattyid
        decass = VACOLS::Decass.where(defolder: vacols_case.bfkey).first
        expect(decass.present?).to eq true
        expect(decass.deatty).to eq attorney_staff.sattyid
        expect(decass.deteam).to eq attorney_staff.stitle[0..2]
        expect(decass.demdusr).to eq judge_staff.slogid
        expect(decass.deadtim).to eq date_added
        expect(decass.dedeadline).to eq VacolsHelper.local_date_with_utc_timezone + 30.days
        expect(decass.deassign).to eq VacolsHelper.local_date_with_utc_timezone
      end
    end

    context "when vacols ID and date added are not valid" do
      let(:date_added) { "2018-04-18".to_date }
      let!(:decass) { create(:decass, defolder: vacols_case.bfkey, deadtim: "2014-04-18".to_date) }

      it "should raise Caseflow::Error::QueueRepositoryError" do
        expect { subject }.to raise_error(Caseflow::Error::QueueRepositoryError)
      end
    end
  end

  context ".filter_duplicate_tasks" do
    let(:judge) { User.create(css_id: "BAWS123", station_id: User::BOARD_STATION_ID) }
    let(:attorney) { User.create(css_id: "FATR456", station_id: User::BOARD_STATION_ID) }
    let!(:judge_staff) do
      create(:staff, :judge_role, slogid: "BVABAWS", sdomainid: judge.css_id)
    end
    let!(:attorney_staff) do
      create(:staff, :attorney_role, stitle: "DF", slogid: "BVASAMD", sdomainid: attorney.css_id, sattyid: "1234")
    end

    context "when current user an attorney" do
      before do
        RequestStore[:current_user] = attorney
      end
      subject { QueueRepository.filter_duplicate_tasks(tasks) }

      let(:tasks) do
        [
          OpenStruct.new(vacols_id: "123B", updated_at: 3.days.ago),
          OpenStruct.new(vacols_id: "123B", updated_at: 1.day.ago),
          OpenStruct.new(vacols_id: "123C", updated_at: 2.days.ago),
          OpenStruct.new(vacols_id: "123C", updated_at: 11.days.ago),
          OpenStruct.new(vacols_id: "123C", updated_at: 9.days.ago, attorney_id: "1234"),
          OpenStruct.new(vacols_id: "123A", updated_at: 9.days.ago),
          OpenStruct.new(vacols_id: "123F", updated_at: 2.days.ago),
          OpenStruct.new(vacols_id: "123F", updated_at: 11.days.ago, attorney_id: "5678")
        ]
      end

      it "should filter duplicate tasks and keep the latest" do
        expect(subject.size).to eq 4
        expect(subject).to include tasks[1]
        expect(subject).to include tasks[4]
        expect(subject).to include tasks[5]
        expect(subject).to include tasks[6]
      end
    end

    context "when current user a judge" do
      before do
        RequestStore[:current_user] = judge
      end
      subject { QueueRepository.filter_duplicate_tasks(tasks) }

      let(:tasks) do
        [
          OpenStruct.new(vacols_id: "123B", updated_at: 3.days.ago),
          OpenStruct.new(vacols_id: "123B", updated_at: 1.day.ago),
          OpenStruct.new(vacols_id: "123C", updated_at: 2.days.ago),
          OpenStruct.new(vacols_id: "123C", updated_at: 11.days.ago),
          OpenStruct.new(vacols_id: "123C", updated_at: 9.days.ago, attorney_id: "1234"),
          OpenStruct.new(vacols_id: "123A", updated_at: 9.days.ago),
          OpenStruct.new(vacols_id: "123F", updated_at: 2.days.ago),
          OpenStruct.new(vacols_id: "123F", updated_at: 11.days.ago, attorney_id: "5678")
        ]
      end

      it "should filter duplicate tasks and keep the latest" do
        expect(subject.size).to eq 4
        expect(subject).to include tasks[1]
        expect(subject).to include tasks[2]
        expect(subject).to include tasks[5]
        expect(subject).to include tasks[6]
      end
    end
  end
end
