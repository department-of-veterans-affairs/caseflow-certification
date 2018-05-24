describe LegacyAppeal do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:appeal) do
    Generators::LegacyAppeal.build(
      notification_date: notification_date,
      nod_date: nod_date,
      soc_date: soc_date,
      form9_date: form9_date,
      ssoc_dates: ssoc_dates,
      certification_date: certification_date,
      documents: documents,
      hearing_request_type: hearing_request_type,
      video_hearing_requested: video_hearing_requested,
      appellant_first_name: "Joe",
      appellant_middle_initial: "E",
      appellant_last_name: "Tester",
      decision_date: decision_date,
      manifest_vbms_fetched_at: appeal_manifest_vbms_fetched_at,
      manifest_vva_fetched_at: appeal_manifest_vva_fetched_at,
      location_code: location_code,
      status: status,
      disposition: disposition
    )
  end

  let(:appeal_no_appellant) do
    Generators::LegacyAppeal.build(
      nod_date: nod_date,
      soc_date: soc_date,
      form9_date: form9_date,
      ssoc_dates: ssoc_dates,
      documents: documents,
      hearing_request_type: hearing_request_type,
      video_hearing_requested: video_hearing_requested,
      appellant_first_name: nil,
      appellant_middle_initial: nil,
      appellant_last_name: nil
    )
  end

  let(:notification_date) { 1.month.ago }
  let(:nod_date) { 3.days.ago }
  let(:soc_date) { 1.day.ago }
  let(:form9_date) { 1.day.ago }
  let(:ssoc_dates) { [] }
  let(:certification_date) { nil }
  let(:decision_date) { nil }
  let(:documents) { [] }
  let(:hearing_request_type) { :central_office }
  let(:video_hearing_requested) { false }
  let(:location_code) { nil }
  let(:status) { "Advance" }
  let(:disposition) { nil }

  let(:yesterday) { 1.day.ago.to_formatted_s(:short_date) }
  let(:twenty_days_ago) { 20.days.ago.to_formatted_s(:short_date) }
  let(:last_year) { 365.days.ago.to_formatted_s(:short_date) }

  let(:appeal_manifest_vbms_fetched_at) { Time.zone.local(1954, "mar", 16, 8, 2, 55) }
  let(:appeal_manifest_vva_fetched_at) { Time.zone.local(1987, "mar", 15, 20, 15, 1) }

  let(:service_manifest_vbms_fetched_at) { Time.zone.local(1989, "nov", 23, 8, 2, 55) }
  let(:service_manifest_vva_fetched_at) { Time.zone.local(1989, "dec", 13, 20, 15, 1) }

  let!(:efolder_fetched_at_format) { "%FT%T.%LZ" }
  let(:doc_struct) do
    {
      documents: documents,
      manifest_vbms_fetched_at: service_manifest_vbms_fetched_at.utc.strftime(efolder_fetched_at_format),
      manifest_vva_fetched_at: service_manifest_vva_fetched_at.utc.strftime(efolder_fetched_at_format)
    }
  end

  context "Works with FACOLS" do
    before do
      FeatureToggle.enable!(:test_facols)
    end

    after do
      FeatureToggle.disable!(:test_facols)
    end

    let(:appeal) do
      FactoryBot.create(:legacy_appeal, vacols_case: vacols_case)
    end

    context "#documents_with_type" do
      subject { appeal.documents_with_type(*type) }
      let(:documents) do
        [
          FactoryBot.build(:document, type: "NOD", received_at: 7.days.ago),
          FactoryBot.build(:document, type: "BVA Decision", received_at: 7.days.ago),
          FactoryBot.build(:document, type: "BVA Decision", received_at: 6.days.ago),
          FactoryBot.build(:document, type: "SSOC", received_at: 6.days.ago)
        ]
      end

      let(:vacols_case) do
        FactoryBot.create(:case, documents: documents)
      end

      context "when 1 type is passed" do
        let(:type) { "BVA Decision" }
        it "returns right number of documents and type" do
          expect(subject.count).to eq(2)
          expect(subject.first.type).to eq(type)
        end
      end

      context "when 2 types are passed" do
        let(:type) { %w[NOD SSOC] }
        it "returns right number of documents and type" do
          expect(subject.count).to eq(2)
          expect(subject.first.type).to eq(type.first)
          expect(subject.last.type).to eq(type.last)
        end
      end
    end

    context "#nod" do
      let(:vacols_case) do
        FactoryBot.create(:case_with_nod)
      end

      subject { appeal.nod }
      it { is_expected.to have_attributes(type: "NOD", vacols_date: vacols_case.bfdnod) }

      context "when nod_date is nil" do
        let(:vacols_case) do
          FactoryBot.create(:case)
        end
        let(:nod_date) { nil }
        it { is_expected.to be_nil }
      end
    end

    context "#soc" do
      let(:vacols_case) do
        FactoryBot.create(:case_with_soc)
      end

      subject { appeal.soc }
      it { is_expected.to have_attributes(type: "SOC", vacols_date: vacols_case.bfdsoc) }

      context "when soc_date is nil" do
        let(:vacols_case) do
          FactoryBot.create(:case)
        end
        let(:soc_date) { nil }
        it { is_expected.to be_nil }
      end
    end

    context "#form9" do
      let(:vacols_case) do
        FactoryBot.create(:case_with_form_9)
      end

      subject { appeal.form9 }
      it { is_expected.to have_attributes(type: "Form 9", vacols_date: vacols_case.bfd19) }

      context "when form9_date is nil" do
        let(:vacols_case) do
          FactoryBot.create(:case)
        end
        let(:form9_date) { nil }
        it { is_expected.to be_nil }
      end
    end

    context "#ssocs" do
      let(:vacols_case) do
        FactoryBot.create(:case)
      end
      subject { appeal.ssocs }

      context "when there are no ssoc dates" do
        it { is_expected.to eq([]) }
      end

      context "when there are ssoc dates" do
        let(:vacols_case) do
          FactoryBot.create(:case_with_ssoc)
        end

        it "returns array of ssoc documents" do
          expect(subject.first).to have_attributes(vacols_date: vacols_case.bfssoc1)
          expect(subject.last).to have_attributes(vacols_date: vacols_case.bfssoc2)
        end
      end
    end

    context "#v1_events" do
      subject { appeal.v1_events }

      let(:vacols_case) do
        FactoryBot.create(:case_with_soc)
      end

      it "returns list of events sorted from oldest to newest by date" do
        expect(subject.length > 1).to be_truthy
        expect(subject.first.date.to_date).to eq(vacols_case.bfdnod)
        expect(subject.first.type).to eq(:nod)
      end
    end

    context "#form9_due_date" do
      subject { appeal.form9_due_date }

      context "when the notification date is within the last year" do
        let(:vacols_case) do
          FactoryBot.create(:case_with_notification_date)
        end

        it { is_expected.to eq((vacols_case.bfdrodec + 1.year).to_date) }
      end

      context "when the notification date is older" do
        let(:vacols_case) do
          FactoryBot.create(:case_with_notification_date, bfdrodec: 13.months.ago, bfdsoc: 1.day.ago)
        end

        it { is_expected.to eq((vacols_case.bfdsoc + 60.days).to_date) }
      end

      context "when missing notification date or soc date" do
        let(:vacols_case) do
          FactoryBot.create(:case)
        end

        let(:soc_date) { nil }
        it { is_expected.to eq(nil) }
      end
    end

    context "#cavc_due_date" do
      subject { appeal.cavc_due_date }

      context "when there is no decision date" do
        let(:vacols_case) do
          FactoryBot.create(:case)
        end

        it { is_expected.to eq(nil) }
      end

      context "when there is a decision date" do
        let(:vacols_case) do
          FactoryBot.create(:case_with_decision, bfddec: 30.days.ago)
        end

        it { is_expected.to eq(90.days.from_now.to_date) }
      end
    end

    context "#events" do
      let(:vacols_case) do
        FactoryBot.create(:case_with_form_9)
      end

      subject { appeal.events }

      it "returns list of events" do
        expect(!subject.empty?).to be_truthy
        expect(subject.count { |event| event.type == :claim_decision } > 0).to be_truthy
        expect(subject.count { |event| event.type == :nod } > 0).to be_truthy
        expect(subject.count { |event| event.type == :soc } > 0).to be_truthy
        expect(subject.count { |event| event.type == :form9 } > 0).to be_truthy
      end
    end

    context "#documents_match?" do
      subject { appeal.documents_match? }

      context "when there is an nod, soc, and form9 document matching the respective dates" do
        context "when there are no ssocs" do
          let(:vacols_case) do
            FactoryBot.create(:case_with_form_9)
          end

          it { is_expected.to be_truthy }
        end

        context "when ssoc dates don't match" do
          let(:vacols_case) do
            FactoryBot.create(:case_with_ssoc, bfssoc1: 2.days.ago, bfssoc2: 2.days.ago)
          end

          it { is_expected.to be_falsy }
        end

        context "when received_at is nil" do
          let(:ssoc_documents) do
            [
              FactoryBot.build(:document, type: "SSOC", received_at: nil),
              FactoryBot.build(:document, type: "SSOC", received_at: 1.month.ago)
            ]
          end
          let(:vacols_case) do
            FactoryBot.create(:case_with_ssoc, ssoc_documents: ssoc_documents)
          end

          it { is_expected.to be_falsy }
        end

        context "and ssoc dates match" do
          let(:vacols_case) do
            FactoryBot.create(:case_with_ssoc)
          end

          it { is_expected.to be_truthy }
        end
      end

      context "when the nod date is mismatched" do
        let(:nod_document) do
          [FactoryBot.build(:document, type: "NOD", received_at: 1.day.ago)]
        end

        let(:vacols_case) do
          FactoryBot.create(:case_with_ssoc, nod_document: nod_document)
        end

        it { is_expected.to be_falsy }
      end

      context "when the soc date is mismatched" do
        let(:soc_document) do
          [FactoryBot.build(:document, type: "SOC", received_at: 1.day.ago)]
        end

        let(:vacols_case) do
          FactoryBot.create(:case_with_ssoc, soc_document: soc_document)
        end

        it { is_expected.to be_falsy }
      end

      context "when the form9 date is mismatched" do
        let(:form9_document) do
          [FactoryBot.build(:document, type: "Form9", received_at: 1.day.ago)]
        end

        let(:vacols_case) do
          FactoryBot.create(:case_with_ssoc, form9_document: form9_document)
        end

        it { is_expected.to be_falsy }
      end

      context "when at least one ssoc doesn't match" do
        let(:vacols_case) do
          FactoryBot.create(:case_with_ssoc, bfssoc1: 2.days.ago)
        end

        it { is_expected.to be_falsy }
      end

      context "when one of the dates is missing" do
        let(:vacols_case) do
          FactoryBot.create(:case_with_ssoc, bfdnod: nil)
        end

        it { is_expected.to be_falsy }
      end
    end

    context "#serialized_decision_date" do
      let(:appeal) { LegacyAppeal.new(decision_date: decision_date) }
      subject { appeal.serialized_decision_date }

      context "when decision date is nil" do
        let(:decision_date) { nil }
        it { is_expected.to eq("") }
      end

      context "when decision date exists" do
        let(:decision_date) { Time.zone.local(2016, 9, 6) }
        it { is_expected.to eq("2016/09/06") }
      end
    end

    context "#number_of_documents" do
      let(:documents) do
        [FactoryBot.build(:document, type: "NOD"),
         FactoryBot.build(:document, type: "SOC"),
         FactoryBot.build(:document, type: "SSOC")]
      end

      let(:vacols_case) do
        FactoryBot.create(:case, documents: documents)
      end

      subject { appeal.number_of_documents }

      it "should return number of documents" do
        expect(subject).to eq 3
      end
    end

    context "#number_of_documents_after_certification" do
      let(:documents) do
        [FactoryBot.build(:document, type: "NOD", received_at: 4.days.ago),
         FactoryBot.build(:document, type: "SOC", received_at: 1.day.ago),
         FactoryBot.build(:document, type: "SSOC", received_at: 5.days.ago)]
      end

      let(:vacols_case) do
        FactoryBot.create(:case, :certified, documents: documents, certification_date: certification_date)
      end

      subject { appeal.number_of_documents_after_certification }

      context "when certification_date is nil" do
        let(:certification_date) { nil }

        it { is_expected.to eq 0 }
      end

      context "when certification_date is set" do
        let(:certification_date) { 2.days.ago }

        it do
          is_expected.to eq 1
        end
      end
    end

    context "#in_location?" do
      let(:vacols_case) do
        FactoryBot.create(:case, bfcurloc: location_code)
      end

      let(:location_code) { "96" }

      subject { appeal.in_location?(location) }
      let(:location) { :remand_returned_to_bva }

      context "when location is not recognized" do
        let(:location) { :never_never_land }

        it "raises error" do
          expect { subject }.to raise_error(LegacyAppeal::UnknownLocationError)
        end
      end

      context "when is in location" do
        it { is_expected.to be_truthy }
      end

      context "when is not in location" do
        let(:location_code) { "97" }
        it { is_expected.to be_falsey }
      end
    end

    context "#case_assignment_exists" do
      let(:vacols_case) do
        FactoryBot.create(:case, :assigned)
      end

      subject { appeal.case_assignment_exists }

      it { is_expected.to be_truthy }
    end

    context ".find_or_create_by_vacols_id" do
      let!(:vacols_case) do
        FactoryBot.create(:case, bfkey: "123C")
      end

      subject { LegacyAppeal.find_or_create_by_vacols_id("123C") }

      context "when no appeal exists for VACOLS id" do
        context "when no VACOLS data exists for that appeal" do
          let!(:vacols_case) {}

          it "raises ActiveRecord::RecordNotFound error" do
            expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end

        context "when VACOLS data exists for that appeal" do
          it "saves and returns that appeal with updated VACOLS data loaded" do
            is_expected.to be_persisted
            expect(subject.vbms_id).to eq(vacols_case.bfcorlid)
          end
        end
      end

      context "when appeal with VACOLS id exists in the DB" do
        before { FactoryBot.create(:legacy_appeal, vacols_id: "123C", vbms_id: "456VBMS") }

        context "when no VACOLS data exists for that appeal" do
          let!(:vacols_case) {}

          it "raises ActiveRecord::RecordNotFound error" do
            expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end

        context "when VACOLS data exists for that appeal" do
          it "saves and returns that appeal with updated VACOLS data loaded" do
            expect(subject.reload.id).to_not be_nil
            expect(subject.vbms_id).to eq(vacols_case.bfcorlid)
          end
        end
      end

      context "sets the vacols_id" do
        before do
          allow_any_instance_of(LegacyAppeal).to receive(:save) {}
        end

        it do
          is_expected.to be_an_instance_of(LegacyAppeal)
          expect(subject.vacols_id).to eq("123C")
        end
      end

      it "persists in database" do
        expect(LegacyAppeal.find_by(vacols_id: subject.vacols_id)).to be_an_instance_of(LegacyAppeal)
      end
    end

    context ".close" do
      let(:vacols_case) do
        FactoryBot.create(:case_with_nod)
      end
      let(:another_vacols_case) do
        FactoryBot.create(:case_with_decision, :status_remand)
      end

      let(:issues) { [] }
      let(:appeal_with_decision) do
        FactoryBot.create(:legacy_appeal, vacols_case: another_vacols_case)
      end
      let(:user) { Generators::User.build }
      let(:disposition) { "RAMP Opt-in" }
      let(:election_receipt_date) { 2.days.ago }

      before do
        RequestStore[:current_user] = user
      end

      context "when called with both appeal and appeals" do
        it "should raise error" do
          expect do
            LegacyAppeal.close(
              appeal: appeal,
              appeals: [appeal, appeal_with_decision],
              user: user,
              closed_on: 4.days.ago,
              disposition: disposition,
              election_receipt_date: election_receipt_date
            )
          end.to raise_error("Only pass either appeal or appeals")
        end
      end

      context "when multiple appeals" do
        let(:vacols_case_with_recent_nod) do
          FactoryBot.create(:case_with_nod, bfdnod: 1.day.ago)
        end
        let(:appeal_with_nod_after_election_received) do
          FactoryBot.create(:legacy_appeal, vacols_case: vacols_case_with_recent_nod)
        end

        it "closes each appeal with nod_date before election received_date" do
          LegacyAppeal.close(
            appeals: [appeal, appeal_with_decision, appeal_with_nod_after_election_received],
            user: user,
            closed_on: 4.days.ago,
            disposition: disposition,
            election_receipt_date: election_receipt_date
          )

          expect(vacols_case.reload.bfmpro).to eq("HIS")
          expect(another_vacols_case.reload.bfmpro).to eq("HIS")
          expect(vacols_case_with_recent_nod.reload.bfmpro).to_not eq("HIS")
        end
      end

      context "when just one appeal" do
        subject do
          LegacyAppeal.close(
            appeal: appeal,
            user: user,
            closed_on: 4.days.ago,
            disposition: disposition,
            election_receipt_date: election_receipt_date
          )
        end

        context "when disposition is not valid" do
          let(:disposition) { "I'm not a disposition" }

          it "should raise error" do
            expect { subject }.to raise_error(/Disposition/)
          end
        end

        context "when disposition is valid" do
          context "when appeal is not active" do
            let(:vacols_case) { FactoryBot.create(:case_with_nod, :status_complete) }

            it "should raise error" do
              expect { subject }.to raise_error(/active/)
            end
          end

          context "when appeal is active and undecided" do
            it "closes the appeal in VACOLS" do
              subject

              expect(vacols_case.reload.bfmpro).to eq("HIS")
              expect(vacols_case.reload.bfdc).to eq("P")
              expect(vacols_case.folder.reload.timduser).to eq(user.regional_office)
            end
          end

          context "when appeal is a remand" do
            let(:vacols_case) do
              FactoryBot.create(:case_with_decision, case_issues: [FactoryBot.create(:case_issue, :disposition_allowed)])
            end

            it "closes the remand in VACOLS" do
              subject

              expect(vacols_case.reload.bfmpro).to eq("HIS")
              expect(vacols_case.reload.bfcurloc).to eq("99")
            end
          end
        end
      end
    end

    context ".reopen" do
      subject do
        LegacyAppeal.reopen(
          appeals: [appeal, undecided_appeal],
          user: user,
          disposition: disposition
        )
      end
      let(:vacols_case) do
        FactoryBot.create(:case_with_nod, :status_complete, :disposition_allowed)
      end
      let(:ramp_vacols_case) do
        FactoryBot.create(:case_with_decision, :status_complete, :disposition_ramp, bfboard: "00")
      end

      let(:user) { Generators::User.build }
      let(:disposition) { "RAMP Opt-in" }

      let(:undecided_appeal) do
        FactoryBot.create(:legacy_appeal, vacols_case: ramp_vacols_case)
      end

      context "with valid appeals" do
        let!(:followup_case) do
          FactoryBot.create(
            :case,
            bfkey: "#{vacols_case.bfkey}#{Constants::VACOLS_DISPOSITIONS_BY_ID.key(disposition)}")
        end

        before do
          RequestStore[:current_user] = user
          vacols_case.update_vacols_location!("50")
          vacols_case.update_vacols_location!("99")
          vacols_case.reload

          ramp_vacols_case.update_vacols_location!("77")
          ramp_vacols_case.update_vacols_location!("99")
          ramp_vacols_case.reload
        end

        it "reopens each appeal according to it's type" do
          subject

          expect(vacols_case.reload.bfmpro).to eq("REM")
          expect(ramp_vacols_case.reload.bfmpro).to eq("ADV")
        end
      end

      context "disposition doesn't exist" do
        let(:disposition) { "I'm not a disposition" }

        it "should raise error" do
          expect { subject }.to raise_error(/Disposition/)
        end
      end

      context "one of the non-remand appeals is active" do
        let(:vacols_case) do
          FactoryBot.create(:case_with_nod, :status_active, :disposition_allowed)
        end

        it "should raise error" do
          expect { subject }.to raise_error("Only closed appeals can be reopened")
        end
      end
    end

    context "#certify!" do
      let(:vacols_case) { FactoryBot.create(:case) }
      subject { appeal.certify! }

      context "when form8 for appeal exists in the DB" do
        before do
          @form8 = Form8.create(vacols_id: appeal.vacols_id)
          @certification = Certification.create(vacols_id: appeal.vacols_id, hearing_preference: "VIDEO")
        end

        it "certifies the appeal using AppealRepository" do
          expect { subject }.to_not raise_error
          expect(vacols_case.reload.bf41stat).to_not be_nil
        end

        it "uploads the correct form 8 using AppealRepository" do
          expect { subject }.to_not raise_error
          expect(Fakes::VBMSService.uploaded_form8.id).to eq(@form8.id)
          expect(Fakes::VBMSService.uploaded_form8_appeal).to eq(appeal)
        end
      end

      context "when a cancelled certification for an appeal already exists in the DB" do
        before do
          @form8 = Form8.create(vacols_id: appeal.vacols_id)
          @cancelled_certification = Certification.create!(
            vacols_id: appeal.vacols_id, hearing_preference: "SOME_INVALID_PREF"
          )
          CertificationCancellation.create!(
            certification_id: @cancelled_certification.id,
            cancellation_reason: "reason",
            email: "test@caseflow.gov"
          )
          @certification = Certification.create!(vacols_id: appeal.vacols_id, hearing_preference: "VIDEO")
        end

        it "certifies the correct appeal using AppealRepository" do
          expect { subject }.to_not raise_error
          expect(vacols_case.reload.bfhr).to eq(VACOLS::Case::HEARING_PREFERENCE_TYPES_V2[:VIDEO][:vacols_value])
        end
      end

      context "when form8 doesn't exist in the DB for appeal" do
        it "throws an error" do
          expect { subject }.to raise_error("No Form 8 found for appeal being certified")
        end
      end
    end

    context "#certified?" do
      context "when case has certification date" do
        let(:vacols_case) do
          FactoryBot.create(:case, :certified, certification_date: 2.days.ago)
        end

        it "is true" do
          expect(appeal.certified?).to be_truthy
        end
      end

      context "when case doesn't have certification date" do
        let(:vacols_case) do
          FactoryBot.create(:case)
        end

        it "is false" do
          expect(appeal.certified?).to be_falsy
        end
      end
    end

    context "#hearing_pending?" do
      subject { LegacyAppeal.new(hearing_requested: false, hearing_held: false) }

      it "determines whether an appeal is awaiting a hearing" do
        expect(subject.hearing_pending?).to be_falsy
        subject.hearing_requested = true
        expect(subject.hearing_pending?).to be_truthy
        subject.hearing_held = true
        expect(subject.hearing_pending?).to be_falsy
      end
    end

    context "#sanitized_vbms_id" do
      subject { LegacyAppeal.new(vbms_id: "123C") }

      it "left-pads case-number ids" do
        expect(subject.sanitized_vbms_id).to eq("00000123")
      end

      it "left-pads 7-digit case-number ids" do
        subject.vbms_id = "2923988C"
        expect(subject.sanitized_vbms_id).to eq("02923988")
      end

      it "doesn't left-pad social security ids" do
        subject.vbms_id = "123S"
        expect(subject.sanitized_vbms_id).to eq("123")
      end
    end

    context "#fetch_appeals_by_file_number" do
      subject { LegacyAppeal.fetch_appeals_by_file_number(file_number) }
      let!(:vacols_case) do
        FactoryBot.create(:case, bfcorlid: "123456789S")
      end

      context "when passed with valid vbms id" do
        let(:file_number) { "123456789" }

        it "returns an appeal" do
          expect(subject.length).to eq(1)
          expect(subject[0].vbms_id).to eq("123456789S")
        end
      end

      context "when passed an invalid vbms id" do
        context "length greater than 9" do
          let(:file_number) { "1234567890" }

          it "raises ActiveRecord::RecordNotFound error" do
            expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end

        context "length less than 3" do
          let(:file_number) { "12" }

          it "raises ActiveRecord::RecordNotFound error" do
            expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end

    context ".convert_file_number_to_vacols" do
      subject { LegacyAppeal.convert_file_number_to_vacols(file_number) }

      context "for a file number with less than 9 digits" do
        context "with leading zeros" do
          let(:file_number) { "00001234" }
          it { is_expected.to eq("1234C") }
        end

        context "with no leading zeros" do
          let(:file_number) { "12345678" }
          it { is_expected.to eq("12345678C") }
        end
      end

      context "for a file number with 9 digits" do
        let(:file_number) { "123456789" }
        it { is_expected.to eq("123456789S") }

        context "with letters" do
          let(:file_number) { "12ABCSD34ASDASD56789S" }
          it { is_expected.to eq("123456789S") }
        end

        context "with leading zeros and letters" do
          let(:file_number) { "00123C00S9S" }
          it { is_expected.to eq("123009C") }
        end
      end

      context "for a file number with more than 9 digits" do
        let(:file_number) { "1234567890" }

        it "raises InvalidFileNumber error" do
          expect { subject }.to raise_error(Caseflow::Error::InvalidFileNumber)
        end
      end
    end

    context "#partial_grant_on_dispatch?" do
      let!(:vacols_case) do
        FactoryBot.create(:case, :status_remand, case_issues: issues)
      end
      subject { appeal.partial_grant_on_dispatch? }

      context "when no allowed issues" do
        let(:issues) { [FactoryBot.create(:case_issue, :disposition_remanded)] }

        it { is_expected.to be_falsey }
      end

      context "when the allowed issues are new material" do
        let(:issues) { [FactoryBot.create(:case_issue, :disposition_allowed, :compensation)] }

        it { is_expected.to be_falsey }
      end

      context "when there's a mix of allowed and remanded issues" do
        let(:issues) do
          [
            FactoryBot.create(:case_issue, :disposition_allowed, issprog: "02", isscode: "15", isslev1: "03", isslev2: "5252"),
            FactoryBot.create(:case_issue, :disposition_remanded, issprog: "02", isscode: "15", isslev1: "03", isslev2: "5252")
          ]
        end

        it { is_expected.to be_truthy }
      end
    end

    context "#full_grant_on_dispatch?" do
      let(:issues) { [] }

      subject { appeal.full_grant_on_dispatch? }

      context "when status is Remand" do
        let!(:vacols_case) { FactoryBot.create(:case, :status_remand) }
        it { is_expected.to be_falsey }
      end

      context "when status is Complete" do
        let!(:vacols_case) { FactoryBot.create(:case, :status_complete, case_issues: issues) }

        context "when at least one issues is new-material allowed" do
          let(:issues) do
            [
              FactoryBot.create(:case_issue, :disposition_allowed, :compensation),
              FactoryBot.create(:case_issue, :disposition_denied)
            ]
          end
          it { is_expected.to be_falsey }
        end

        context "when at least one issue is not new-material allowed" do
          let(:issues) do
            [
              FactoryBot.create(:case_issue, :disposition_allowed),
              FactoryBot.create(:case_issue, :disposition_denied)
            ]
          end
          it { is_expected.to be_truthy }
        end
      end
    end

    context "#remand_on_dispatch?" do
      subject { appeal.remand_on_dispatch? }

      context "status is not remand" do
        let!(:vacols_case) { FactoryBot.create(:case, :status_complete) }
        it { is_expected.to be false }
      end

      context "status is remand" do
        let!(:vacols_case) { FactoryBot.create(:case, :status_remand, case_issues: issues) }

        context "contains at least one new-material allowed issue" do
          let(:issues) do
            [
              FactoryBot.create(:case_issue, :disposition_allowed),
              FactoryBot.create(:case_issue, :disposition_remanded)
            ]
          end

          it { is_expected.to be false }
        end

        context "contains no new-material allowed issues" do
          let(:issues) do
            [
              FactoryBot.create(:case_issue, :disposition_allowed, :compensation),
              FactoryBot.create(:case_issue, :disposition_remanded)
            ]
          end

          it { is_expected.to be true }
        end
      end
    end

    context "#decided_by_bva?" do
      subject { appeal.decided_by_bva? }

      context "when status is not Complete" do
        let!(:vacols_case) { FactoryBot.create(:case, :status_remand, :disposition_remanded) }
        it { is_expected.to be false }
      end

      context "when status is Complete" do
        let!(:vacols_case) { FactoryBot.create(:case, :status_complete, :disposition_remanded) }

        context "when disposition is a BVA disposition" do
          it { is_expected.to be true }
        end

        context "when disposition is not a BVA disposition" do
          let!(:vacols_case) { FactoryBot.create(:case, :status_remand, :disposition_ramp) }
          it { is_expected.to be false }
        end
      end
    end

    context "#compensation_issues" do
      subject { appeal.compensation_issues }

      let!(:vacols_case) { FactoryBot.create(:case, case_issues: issues) }
      let(:compensation_issue) do
        FactoryBot.create(
          :case_issue, :disposition_allowed, :compenstation)
      end
      let(:issues) do
        [
          compensation_issue,
          FactoryBot.create(
            :case_issue, :disposition_allowed, :education)
        ]
      end

      it { expect(subject[0].vacols_sequence_id).to eq(compensation_issue.issseq) }
    end

    context "#compensation?" do
      subject { appeal.compensation? }

      let!(:vacols_case) { FactoryBot.create(:case, case_issues: issues) }
      let(:compensation_issue) do
        FactoryBot.create(
          :case_issue, :disposition_allowed, :compensation)
      end
      let(:education_issue) do
        FactoryBot.create(
          :case_issue, :disposition_allowed, :education)
      end

      context "when there are no compensation issues" do
        let(:issues) { [education_issue] }
        it { is_expected.to be false }
      end

      context "when there is at least 1 compensation issue" do
        let(:issues) { [education_issue, compensation_issue] }
        it { is_expected.to be true }
      end
    end

    context "#fully_compensation?" do
      subject { appeal.fully_compensation? }

      let!(:vacols_case) { FactoryBot.create(:case, case_issues: issues) }
      let(:compensation_issue) do
        FactoryBot.create(
          :case_issue, :disposition_allowed, :compensation)
      end
      let(:education_issue) do
        FactoryBot.create(
          :case_issue, :disposition_allowed, :education)
      end

      context "when there is at least one non-compensation issue" do
        let(:issues) { [education_issue, compensation_issue] }
        it { is_expected.to be false }
      end

      context "when there are all compensation issues" do
        let(:issues) { [compensation_issue] }
        it { is_expected.to be true }
      end
    end

    context "#eligible_for_ramp?" do
      subject { appeal.eligible_for_ramp? }

      let(:location_code) { nil }

      context "is false if status is not advance or remand" do
        let!(:vacols_case) { FactoryBot.create(:case, :status_active) }
        it { is_expected.to be_falsey }
      end

      context "status is remand" do
        let!(:vacols_case) { FactoryBot.create(:case, :status_remand) }
        it { is_expected.to be_truthy }
      end

      context "status is advance" do
        context "location is remand_returned_to_bva" do
          let!(:vacols_case) { FactoryBot.create(:case, :status_advance, bfcurloc: "96") }
          it { is_expected.to be_falsey }
        end

        context "location is not remand_returned_to_bva" do
          let!(:vacols_case) { FactoryBot.create(:case, :status_advance, bfcurloc: "90") }
          it { is_expected.to be_truthy }
        end
      end
    end

    context "#disposition_remand_priority" do
      subject { appeal.disposition_remand_priority }
      context "when disposition is allowed and one of the issues is remanded" do
        let(:issues) do
          [
            FactoryBot.create(:case_issue, :disposition_remanded),
            FactoryBot.create(:case_issue, :disposition_allowed)
          ]
        end
        let!(:vacols_case) { FactoryBot.create(:case, :disposition_allowed, case_issues: issues) }
        it { is_expected.to eq("Remanded") }
      end

      context "when disposition is allowed and none of the issues are remanded" do
        let(:issues) do
          [
            FactoryBot.create(:case_issue, :disposition_allowed),
            FactoryBot.create(:case_issue, :disposition_allowed)
          ]
        end
        let!(:vacols_case) { FactoryBot.create(:case, :disposition_allowed, case_issues: issues) }
        it { is_expected.to eq("Allowed") }
      end

      context "when disposition is not allowed" do
        let!(:vacols_case) { FactoryBot.create(:case, :disposition_vacated, case_issues: []) }
        it { is_expected.to eq("Vacated") }
      end
    end
  end

  context "#dispatch_decision_type" do
    subject { appeal.dispatch_decision_type }
    context "when it has a mix of allowed and granted issues" do
      let(:issues) do
        [
          Generators::Issue.build(disposition: :allowed),
          Generators::Issue.build(disposition: :remanded)
        ]
      end
      let(:appeal) { Generators::LegacyAppeal.build(vacols_id: "123", status: "Remand", issues: issues) }
      it { is_expected.to eq("Partial Grant") }
    end

    context "when it has a non-new-material allowed issue" do
      let(:issues) { [Generators::Issue.build(disposition: :allowed)] }
      let(:appeal) { Generators::LegacyAppeal.build(vacols_id: "123", status: "Complete", issues: issues) }
      it { is_expected.to eq("Full Grant") }
    end

    context "when it has a remanded issue" do
      let(:issues) { [Generators::Issue.build(disposition: :remand)] }
      let(:appeal) { Generators::LegacyAppeal.build(vacols_id: "123", status: "Remand") }
      it { is_expected.to eq("Remand") }
    end
  end

  context "#task_header" do
    let(:appeal) do
      LegacyAppeal.new(
        veteran_first_name: "Davy",
        veteran_middle_initial: "Q",
        veteran_last_name: "Crockett",
        vbms_id: "123"
      )
    end

    subject { appeal.task_header }

    it "returns the correct string" do
      expect(subject).to eq("&nbsp &#124; &nbsp Crockett, Davy, Q (123)")
    end
  end

  context "#outcoded_by_name" do
    let(:appeal) do
      LegacyAppeal.new(
        outcoder_last_name: "King",
        outcoder_middle_initial: "Q",
        outcoder_first_name: "Andrew"
      )
    end

    subject { appeal.outcoded_by_name }

    it "returns the correct string" do
      expect(subject).to eq("King, Andrew, Q")
    end
  end

  context "#station_key" do
    let(:appeal) do
      LegacyAppeal.new(
        veteran_first_name: "Davy",
        veteran_middle_initial: "Q",
        veteran_last_name: "Crockett",
        regional_office_key: regional_office_key
      )
    end

    subject { appeal.station_key }

    context "when regional office key is mapped to a station" do
      let(:regional_office_key) { "RO13" }
      it { is_expected.to eq("313") }
    end

    context "when regional office key is one of many mapped to a station" do
      let(:regional_office_key) { "RO16" }
      it { is_expected.to eq("316") }
    end

    context "when regional office key is not mapped to a station" do
      let(:regional_office_key) { "SO62" }
      it { is_expected.to be_nil }
    end
  end

  context "#decisions" do
    subject { appeal.decisions }
    let(:decision) do
      Document.new(received_at: Time.zone.now.to_date, type: "BVA Decision")
    end
    let(:old_decision) do
      Document.new(received_at: 5.days.ago.to_date, type: "BVA Decision")
    end
    let(:appeal) { LegacyAppeal.new(vbms_id: "123") }

    context "when only one decision" do
      before do
        allow(appeal).to receive(:documents).and_return([decision])
        appeal.decision_date = Time.current
      end

      it { is_expected.to eq([decision]) }
    end

    context "when only one recent decision" do
      before do
        allow(appeal).to receive(:documents).and_return([decision, old_decision])
        appeal.decision_date = Time.current
      end

      it { is_expected.to eq([decision]) }
    end

    context "when no recent decision" do
      before do
        allow(appeal).to receive(:documents).and_return([old_decision])
        appeal.decision_date = Time.current
      end

      it { is_expected.to eq([]) }
    end

    context "when no decision_date on appeal" do
      before do
        appeal.decision_date = nil
      end

      it { is_expected.to eq([]) }
    end

    context "when there are two decisions of the same type" do
      let(:documents) { [decision, decision.clone] }

      before do
        allow(appeal).to receive(:documents).and_return(documents)
        appeal.decision_date = Time.current
      end

      it { is_expected.to eq(documents) }
    end

    context "when there are two decisions of the different types" do
      let(:documents) do
        [
          decision,
          Document.new(type: "Remand BVA or CAVC", received_at: 1.day.ago)
        ]
      end

      before do
        allow(appeal).to receive(:documents).and_return(documents)
        appeal.decision_date = Time.current
      end

      it { is_expected.to eq(documents) }
    end
  end

  context "#non_canceled_end_products_within_30_days" do
    let(:appeal) { Generators::LegacyAppeal.build(decision_date: 1.day.ago) }
    let(:result) { appeal.non_canceled_end_products_within_30_days }

    let!(:twenty_day_old_pending_ep) do
      Generators::EndProduct.build(
        veteran_file_number: appeal.sanitized_vbms_id,
        bgs_attrs: {
          claim_receive_date: twenty_days_ago,
          claim_type_code: "172GRANT",
          status_type_code: "PEND"
        }
      )
    end

    let!(:recent_cleared_ep) do
      Generators::EndProduct.build(
        veteran_file_number: appeal.sanitized_vbms_id,
        bgs_attrs: {
          claim_receive_date: yesterday,
          claim_type_code: "170RMD",
          status_type_code: "CLR"
        }
      )
    end

    let!(:recent_cancelled_ep) do
      Generators::EndProduct.build(
        veteran_file_number: appeal.sanitized_vbms_id,
        bgs_attrs: {
          claim_receive_date: yesterday,
          claim_type_code: "172BVAG",
          status_type_code: "CAN"
        }
      )
    end

    let!(:year_old_ep) do
      Generators::EndProduct.build(
        veteran_file_number: appeal.sanitized_vbms_id,
        bgs_attrs: {
          claim_receive_date: last_year,
          claim_type_code: "172BVAG",
          status_type_code: "CLR"
        }
      )
    end

    it "returns correct eps" do
      puts BGSService.end_product_records
      expect(result.length).to eq(2)

      expect(result.first.claim_type_code).to eq("172GRANT")
      expect(result.last.claim_type_code).to eq("170RMD")
    end
  end

  context "#special_issues?" do
    let(:appeal) { LegacyAppeal.new(vacols_id: "123", us_territory_claim_philippines: true) }
    subject { appeal.special_issues? }

    it "is true if any special issues exist" do
      expect(subject).to be_truthy
    end

    it "is false if no special issues exist" do
      appeal.update!(us_territory_claim_philippines: false)
      expect(subject).to be_falsy
    end
  end

  context "#pending_eps" do
    let(:appeal) { Generators::LegacyAppeal.build(decision_date: 1.day.ago) }

    let!(:pending_eps) do
      [
        Generators::EndProduct.build(
          veteran_file_number: appeal.sanitized_vbms_id,
          bgs_attrs: {
            claim_receive_date: twenty_days_ago,
            claim_type_code: "070BVAGR",
            end_product_type_code: "071",
            status_type_code: "PEND"
          }
        ),
        Generators::EndProduct.build(
          veteran_file_number: appeal.sanitized_vbms_id,
          bgs_attrs: {
            claim_receive_date: last_year,
            claim_type_code: "070BVAGRARC",
            end_product_type_code: "070",
            status_type_code: "PEND"
          }
        )
      ]
    end

    let!(:cancelled_ep) do
      Generators::EndProduct.build(
        veteran_file_number: appeal.sanitized_vbms_id,
        bgs_attrs: {
          claim_receive_date: yesterday,
          claim_type_code: "070RMND",
          end_product_type_code: "072",
          status_type_code: "CAN"
        }
      )
    end

    let!(:cleared_ep) do
      Generators::EndProduct.build(
        veteran_file_number: appeal.sanitized_vbms_id,
        bgs_attrs: {
          claim_receive_date: last_year,
          claim_type_code: "172BVAG",
          status_type_code: "CLR"
        }
      )
    end

    let(:result) { appeal.pending_eps }

    it "returns only pending eps" do
      expect(result.length).to eq(2)

      expect(result.first.claim_type_code).to eq("070BVAGR")
      expect(result.last.claim_type_code).to eq("070BVAGRARC")
    end
  end

  context "#special_issues" do
    subject { appeal.special_issues }

    context "when no special issues are true" do
      it { is_expected.to eq([]) }
    end

    context "when one special issue is true" do
      let(:appeal) { LegacyAppeal.new(dic_death_or_accrued_benefits_united_states: true) }
      it { is_expected.to eq(["DIC - death, or accrued benefits - United States"]) }
    end

    context "when many special issues are true" do
      let(:appeal) do
        LegacyAppeal.new(
          foreign_claim_compensation_claims_dual_claims_appeals: true,
          vocational_rehab: true,
          education_gi_bill_dependents_educational_assistance_scholars: true,
          us_territory_claim_puerto_rico_and_virgin_islands: true
        )
      end

      it { expect(subject.length).to eq(4) }
      it { is_expected.to include("Foreign claim - compensation claims, dual claims, appeals") }
      it { is_expected.to include("Vocational Rehab") }
      it { is_expected.to include(/Education - GI Bill, dependents educational assistance/) }
      it { is_expected.to include("U.S. Territory claim - Puerto Rico and Virgin Islands") }
    end
  end

  context "#veteran" do
    subject { appeal.veteran }

    let(:veteran_record) { { file_number: "123", first_name: "Ed", last_name: "Merica" } }

    before do
      Fakes::BGSService.veteran_records = { appeal.sanitized_vbms_id => veteran_record }
    end

    it "returns veteran loaded with BGS values" do
      is_expected.to have_attributes(first_name: "Ed", last_name: "Merica")
    end
  end

  context "#power_of_attorney" do
    subject { appeal.power_of_attorney }

    it "returns poa loaded with VACOLS values" do
      is_expected.to have_attributes(
        vacols_representative_type: "Service Organization",
        vacols_representative_name: "The American Legion"
      )
    end

    it "returns poa loaded with BGS values by default" do
      is_expected.to have_attributes(bgs_representative_type: "Attorney", bgs_representative_name: "Clarence Darrow")
    end

    context "#power_of_attorney(load_bgs_record: false)" do
      subject { appeal.power_of_attorney(load_bgs_record: false) }

      it "returns poa without fetching BGS values if desired" do
        is_expected.to have_attributes(bgs_representative_type: nil, bgs_representative_name: nil)
      end
    end

    context "#power_of_attorney.bgs_representative_address" do
      subject { appeal.power_of_attorney.bgs_representative_address }

      it "returns address if we are able to retrieve it" do
        is_expected.to include(
          address_line_1: "9999 MISSION ST",
          city: "SAN FRANCISCO",
          zip: "94103"
        )
      end
    end
  end

  context "#issue_categories" do
    subject { appeal.issue_categories }

    let(:appeal) do
      Generators::LegacyAppeal.build(issues: issues)
    end

    let(:issues) do
      [
        Generators::Issue.build(disposition: :allowed, codes: %w[02 01]),
        Generators::Issue.build(disposition: :allowed, codes: %w[02 02]),
        Generators::Issue.build(disposition: :allowed, codes: %w[02 01])
      ]
    end

    it { is_expected.to include("02-01") }
    it { is_expected.to include("02-02") }
    it { is_expected.to_not include("02-03") }
    it "returns uniqued issue categories" do
      expect(subject.length).to eq(2)
    end
  end

  context "#worksheet_issues" do
    subject { appeal.worksheet_issues.size }

    context "when appeal does not have any Vacols issues" do
      let(:appeal) { Generators::LegacyAppeal.create(vacols_record: :ready_to_certify) }
      it { is_expected.to eq 0 }
    end

    context "when appeal has Vacols issues" do
      let(:appeal) { Generators::LegacyAppeal.create(vacols_record: :remand_decided) }
      it { is_expected.to eq 2 }
    end
  end

  context "#update" do
    subject { appeal.update(appeals_hash) }
    let(:appeal) { Generators::LegacyAppeal.create(vacols_record: :form9_not_submitted) }

    context "when Vacols does not need an update" do
      let(:appeals_hash) do
        { worksheet_issues_attributes: [{
          remand: true,
          omo: true,
          description: "Cabbage\nPickle",
          notes: "Donkey\nCow",
          from_vacols: true,
          vacols_sequence_id: 1
        }] }
      end

      it "updates worksheet issues" do
        expect(appeal.worksheet_issues.count).to eq(0)
        subject # do update
        expect(appeal.worksheet_issues.count).to eq(1)

        issue = appeal.worksheet_issues.first
        expect(issue.remand).to eq true
        expect(issue.allow).to eq false
        expect(issue.deny).to eq false
        expect(issue.dismiss).to eq false
        expect(issue.omo).to eq true
        expect(issue.description).to eq "Cabbage\nPickle"
        expect(issue.notes).to eq "Donkey\nCow"

        # test that a 2nd save updates the same record, rather than create new one
        id = appeal.worksheet_issues.first.id
        appeals_hash[:worksheet_issues_attributes][0][:deny] = true
        appeals_hash[:worksheet_issues_attributes][0][:notes] = "Tomato"
        appeals_hash[:worksheet_issues_attributes][0][:id] = id

        appeal.update(appeals_hash)

        expect(appeal.worksheet_issues.count).to eq(1)
        issue = appeal.worksheet_issues.first
        expect(issue.id).to eq(id)
        expect(issue.deny).to eq(true)
        expect(issue.remand).to eq(true)
        expect(issue.allow).to eq(false)
        expect(issue.dismiss).to eq(false)
        expect(issue.description).to eq "Cabbage\nPickle"
        expect(issue.notes).to eq "Tomato"

        # soft delete an issue
        appeals_hash[:worksheet_issues_attributes][0][:_destroy] = "1"
        appeal.update(appeals_hash)
        expect(appeal.worksheet_issues.count).to eq(0)
        expect(appeal.worksheet_issues.with_deleted.count).to eq(1)
        expect(appeal.worksheet_issues.with_deleted.first.deleted_at).to_not eq nil
      end
    end
  end

  context "#sanitized_hearing_request_type" do
    subject { appeal.sanitized_hearing_request_type }
    let(:video_hearing_requested) { true }

    context "when central_office" do
      let(:hearing_request_type) { :central_office }
      it { is_expected.to eq(:central_office) }
    end

    context "when travel_board" do
      let(:hearing_request_type) { :travel_board }

      context "when video_hearing_requested" do
        it { is_expected.to eq(:video) }
      end

      context "when video_hearing_requested is false" do
        let(:video_hearing_requested) { false }
        it { is_expected.to eq(:travel_board) }
      end
    end

    context "when unsupported type" do
      let(:hearing_request_type) { :confirmation_needed }
      it { is_expected.to be_nil }
    end
  end

  context "#appellant_last_first_mi" do
    subject { appeal.appellant_last_first_mi }
    it { is_expected.to eql("Tester, Joe E.") }

    context "when appellant has no first name" do
      subject { appeal_no_appellant.appellant_last_first_mi }
      it { is_expected.to be_nil }
    end
  end

  context ".to_hash" do
    context "when issues parameter is nil and contains additional attributes" do
      subject { appeal.to_hash(viewed: true, issues: nil) }

      let!(:appeal) do
        Generators::LegacyAppeal.build(
          vbms_id: "999887777S",
          docket_number: "13 11-265",
          regional_office_key: "RO13",
          type: "Court Remand",
          vacols_record: {
            soc_date: 4.days.ago
          }
        )
      end

      it "includes viewed boolean in hash" do
        expect(subject["viewed"]).to be_truthy
      end

      it "issues is null in hash" do
        expect(subject["issues"]).to be_nil
      end

      it "includes aod, cavc, regional_office and docket_number" do
        expect(subject["aod"]).to be_truthy
        expect(subject["cavc"]).to be_truthy
        expect(subject["regional_office"][:key]).to eq("RO13")
        expect(subject["docket_number"]).to eq("13 11-265")
      end
    end

    context "when issues and viewed attributes are provided" do
      subject { appeal.to_hash(viewed: true, issues: issues) }

      let!(:appeal) do
        Generators::LegacyAppeal.build(
          vbms_id: "999887777S",
          vacols_record: { soc_date: 4.days.ago },
          issues: issues
        )
      end

      let!(:labels) do
        ["Compensation", "Service connection", "Other", "Left knee", "Right knee"]
      end

      let!(:issues) do
        [Generators::Issue.build(disposition: :allowed,
                                 codes: %w[02 15 03 04 05],
                                 labels: labels)]
      end

      it "includes viewed boolean in hash" do
        expect(subject["viewed"]).to be_truthy
      end

      it "includes issues in hash" do
        expect(subject["issues"]).to eq(issues.map(&:attributes))
      end
    end
  end

  context ".for_api" do
    before do
      FeatureToggle.enable!(:test_facols)
    end

    after do
      FeatureToggle.disable!(:test_facols)
    end

    subject { LegacyAppeal.for_api(vbms_id: bfcorlid) }
    let(:bfcorlid) { "VBMS_ID" }
    let(:case_with_form_9) { FactoryBot.create(:case_with_form_9, :original, bfcorlid: bfcorlid) }
    let!(:veteran_appeals) do
      [
        FactoryBot.create(:case_with_soc, :original, bfcorlid: bfcorlid),
        FactoryBot.create(:case_with_soc, :reconsideration, bfcorlid: bfcorlid),
        case_with_form_9,
        FactoryBot.create(:case, :original, bfcorlid: bfcorlid)
      ]
    end

    it "returns filtered appeals with events only for veteran sorted by latest event date" do
      expect(subject.length).to eq(2)
      expect(subject.first.form9_date.to_date).to eq(case_with_form_9.bfd19)
    end
  end

  context ".initialize_appeal_without_lazy_load",
          skip: "Disabled without_lazy_load for appeals for fixing Welcome Gate" do
    let(:date) { Time.zone.today }
    let(:saved_appeal) do
      Generators::LegacyAppeal.build(
        vacols_record: { veteran_first_name: "George" }
      )
    end
    let(:appeal) do
      LegacyAppeal.find_or_initialize_by(vacols_id: saved_appeal.vacols_id,
                                         signed_date: date)
    end

    it "creates an appeals object with attributes" do
      expect(appeal.signed_date).to eq(date)
    end

    it "appeal does not lazy load vacols data" do
      expect { appeal.veteran_first_name }.to raise_error(AssociatedVacolsModel::LazyLoadingTurnedOffError)
    end
  end

  context "#vbms_id" do
    context "when vbms_id exists in the caseflow DB" do
      it "does not make a request to VACOLS" do
        expect(appeal).to receive(:perform_vacols_request)
          .exactly(0).times

        expect(appeal.attributes["vbms_id"]).to_not be_nil
        expect(appeal.vbms_id).to_not be_nil
      end
    end

    context "when vbms_id is nil" do
      let(:no_vbms_id_appeal) { LegacyAppeal.new(vacols_id: appeal.vacols_id) }

      context "when appeal is in the DB" do
        before { no_vbms_id_appeal.save! }

        it "looks up vbms_id in VACOLS and saves" do
          expect(no_vbms_id_appeal).to receive(:perform_vacols_request)
            .exactly(1).times.and_call_original

          expect(no_vbms_id_appeal.attributes["vbms_id"]).to be_nil
          expect(no_vbms_id_appeal.reload.vbms_id).to_not be_nil
        end
      end

      context "when appeal is not in the DB" do
        it "looks up vbms_id in VACOLS but does not save" do
          expect(no_vbms_id_appeal).to receive(:perform_vacols_request)
            .exactly(1).times.and_call_original

          expect(no_vbms_id_appeal.attributes["vbms_id"]).to be_nil
          expect(no_vbms_id_appeal.vbms_id).to_not be_nil
          expect(no_vbms_id_appeal).to_not be_persisted
        end
      end
    end
  end

  context "#save_to_legacy_appeals" do
    let :appeal do
      LegacyAppeal.create!(
        vacols_id: "1234"
      )
    end

    let :legacy_appeal do
      LegacyAppeal.find(appeal.id)
    end

    it "Creates a legacy_appeal when an appeal is created" do
      expect(legacy_appeal).to_not be_nil
      expect(legacy_appeal.attributes).to eq(appeal.attributes)
    end

    it "Updates a legacy_appeal when an appeal is updated" do
      appeal.update!(rice_compliance: TRUE)
      expect(legacy_appeal.attributes).to eq(appeal.attributes)
    end
  end

  context "#destroy_legacy_appeal" do
    let :appeal do
      LegacyAppeal.create!(
        id: 1,
        vacols_id: "1234"
      )
    end

    it "Destroys a legacy_appeal when an appeal is destroyed" do
      appeal.destroy!
      expect(LegacyAppeal.where(id: appeal.id)).to_not exist
    end
  end

  context "#aod" do
    subject { appeal.aod }

    it { is_expected.to be_truthy }
  end

  context "#remand_return_date" do
    subject { appeal.remand_return_date }

    context "when the appeal is active" do
      it { is_expected.to eq(nil) }
    end
  end

  context "#cavc_decisions" do
    subject { appeal.cavc_decisions }

    let!(:cavc_decision) { Generators::CAVCDecision.build(appeal: appeal) }
    let!(:another_cavc_decision) { Generators::CAVCDecision.build(appeal: appeal) }

    it { is_expected.to eq([cavc_decision, another_cavc_decision]) }
  end
end
