describe AppealRepository do
  before do
    FeatureToggle.enable!(:test_facols)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  let(:correspondent_record) do
    OpenStruct.new(
      snamef: "Phil",
      snamemi: "J",
      snamel: "Johnston",
      sspare1: "Chris",
      sspare2: "M",
      sspare3: "Johnston",
      susrtyp: "Brother"
    )
  end

  let(:folder_record) do
    OpenStruct.new(
      tivbms: "Y",
      tinum: "13 11-265"
    )
  end

  let(:case_record) do
    OpenStruct.new(
      bfkey: "123C",
      bfcorlid: "VBMS-ID",
      bfac: "4",
      bfso: "Q",
      bfpdnum: "INSURANCE-LOAN-NUMBER",
      bfdrodec: 11.days.ago,
      bfdnod: 10.days.ago,
      bfdsoc: 9.days.ago,
      bfd19: 8.days.ago,
      bfssoc1: 7.days.ago,
      bfssoc2: 6.days.ago,
      bfha: "6",
      bfhr: "1",
      bfregoff: "DSUSER",
      bfdc: "9",
      bfddec: 1.day.ago,
      correspondent: correspondent_record,
      folder: folder_record,
      issues: [{
        issdesc: "Issue Description",
        issdc: "1",
        issprog: "Issue Program"
      }]
    )
  end

  context ".build_appeal" do
    before do
      allow_any_instance_of(LegacyAppeal).to receive(:check_and_load_vacols_data!).and_return(nil)
    end

    subject { AppealRepository.build_appeal(case_record) }

    it "returns a new appeal" do
      is_expected.to be_an_instance_of(LegacyAppeal)
    end
  end

  context ".load_vacols_data" do
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
    subject { AppealRepository.load_vacols_data(appeal) }
    it do
      expect(AppealRepository).to receive(:set_vacols_values).exactly(1).times
      is_expected.to eq(true)
    end
  end

  context ".normalize_vacols_date" do
    subject { AppealRepository.normalize_vacols_date(datetime) }

    context "when datetime is nil" do
      let(:datetime) { nil }
      it { is_expected.to be_nil }
    end

    context "when datetime is in a non-UTC timezone" do
      before { Time.zone = "America/Chicago" }
      let(:datetime) { Time.new(2013, 9, 5, 16, 0, 0, "-08:00") }
      it { is_expected.to eq(Time.zone.local(2013, 9, 6)) }
    end
  end

  context ".set_vacols_values" do
    before do
      Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
      allow_any_instance_of(LegacyAppeal).to receive(:check_and_load_vacols_data!).and_return(nil)
    end

    subject do
      appeal = LegacyAppeal.new
      AppealRepository.set_vacols_values(
        appeal: appeal,
        case_record: case_record
      )
    end

    it do
      is_expected.to have_attributes(
        vbms_id: "VBMS-ID",
        type: "Reconsideration",
        file_type: "VBMS",
        veteran_first_name: "Phil",
        veteran_middle_initial: "J",
        veteran_last_name: "Johnston",
        appellant_first_name: "Chris",
        appellant_middle_initial: "M",
        appellant_last_name: "Johnston",
        appellant_relationship: "Brother",
        insurance_loan_number: "INSURANCE-LOAN-NUMBER",
        notification_date: AppealRepository.normalize_vacols_date(11.days.ago),
        nod_date: AppealRepository.normalize_vacols_date(10.days.ago),
        soc_date: AppealRepository.normalize_vacols_date(9.days.ago),
        form9_date: AppealRepository.normalize_vacols_date(8.days.ago),
        ssoc_dates: [
          AppealRepository.normalize_vacols_date(7.days.ago),
          AppealRepository.normalize_vacols_date(6.days.ago)
        ],
        hearing_request_type: :central_office,
        hearing_requested: true,
        hearing_held: true,
        regional_office_key: "DSUSER",
        disposition: "Withdrawn",
        decision_date: AppealRepository.normalize_vacols_date(1.day.ago),
        docket_number: "13 11-265"
      )
    end

    context "bfha set to value not represent a held hearing" do
      let(:case_record) do
        OpenStruct.new(
          correspondent: correspondent_record,
          folder: folder_record,
          bfha: "3"
        )
      end

      it { is_expected.to have_attributes(hearing_held: false) }
    end

    context "bfha set to nil" do
      let(:case_record) do
        OpenStruct.new(
          correspondent: correspondent_record,
          folder: folder_record,
          bfha: nil
        )
      end

      it { is_expected.to have_attributes(hearing_held: false) }
    end

    context "No appellant listed" do
      let(:correspondent_record) do
        OpenStruct.new(
          snamef: "Phil",
          snamemi: "J",
          snamel: "Johnston",
          susrtyp: "Brother"
        )
      end

      it { is_expected.to have_attributes(appellant_relationship: "") }
    end

    context "shows cavc as true" do
      let(:case_record) do
        OpenStruct.new(
          correspondent: correspondent_record,
          folder: folder_record,
          bfac: "7"
        )
      end

      it { is_expected.to have_attributes(cavc: true) }
    end
  end

  context ".ssoc_dates_from" do
    subject { AppealRepository.ssoc_dates_from(case_record) }
    it do
      is_expected.to be_an_instance_of(Array)
      expect(subject.all? { |d| d.class == ActiveSupport::TimeWithZone }).to be_truthy
    end
  end

  context ".folder_type_from" do
    subject { AppealRepository.folder_type_from(folder_record) }

    context "detects VBMS folder" do
      it { is_expected.to eq("VBMS") }
    end

    context "detects VVA folder" do
      let(:folder_record) { OpenStruct.new(tisubj2: "Y") }
      it { is_expected.to eq("VVA") }
    end

    context "detects paper" do
      let(:folder_record) { OpenStruct.new(tivbms: "other_val", tisubj2: "other_val") }
      it { is_expected.to eq("Paper") }
    end
  end

  context "#location_after_dispatch" do
    before { LegacyAppeal.repository = Fakes::AppealRepository }

    let(:appeal) do
      create(:legacy_appeal, vacols_case: create(:case))
    end

    let(:special_issues) { {} }

    subject { AppealRepository.location_after_dispatch(appeal: appeal) }

    context "when appeal is inactive (in 'history status')" do
      let(:appeal) do
        create(:legacy_appeal, vacols_case: create(:case, :status_complete))
      end

      it { is_expected.to be_nil }
    end

    context "when appeal is a partial grant" do
      let(:appeal) do
        create(:legacy_appeal, vacols_case: create(:case, :status_remand, :disposition_allowed))
      end

      context "when no special issues" do
        it { is_expected.to eq("98") }
      end

      context "when vamc is true" do
        let(:appeal) do
          create(:legacy_appeal, vacols_case: create(:case), vamc: true)
        end
        it { is_expected.to eq("54") }
      end

      context "when national_cemetery_administration is true" do
        let(:appeal) do
          create(:legacy_appeal, vacols_case: create(:case), national_cemetery_administration: true)
        end
        it { is_expected.to eq("53") }
      end

      context "when a special issue besides vamc and national_cemetery_administration is true" do
        let(:appeal) do
          create(:legacy_appeal, vacols_case: create(:case), radiation: true)
        end
        it { is_expected.to eq("50") }
      end
    end

    context "remand" do
      let(:vacols_record) { :remand }

      context "when no special issues" do
        it { is_expected.to eq("98") }
      end
    end
  end
end
