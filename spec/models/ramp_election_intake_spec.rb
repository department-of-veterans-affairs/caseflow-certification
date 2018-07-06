describe RampElectionIntake do
  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
  end

  before do
    FeatureToggle.enable!(:test_facols)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  let!(:current_user) { User.authenticate! }

  let(:veteran_file_number) { "64205555" }
  let(:user) { build(:default_user) }
  let(:detail) { nil }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }
  let(:compensation_issue) { create(:case_issue, :compensation) }
  let(:issues) { [compensation_issue] }
  let(:completed_at) { nil }
  let(:case_status) { :status_advance }

  let(:intake) do
    RampElectionIntake.new(
      user: user,
      detail: detail,
      veteran_file_number: veteran_file_number,
      completed_at: completed_at
    )
  end

  let(:vacols_case) do
    create(
      :case,
      case_status,
      bfcorlid: "64205555C",
      case_issues: issues,
      bfdnod: 1.year.ago
    )
  end

  context "#cancel!" do
    subject { intake.cancel!(reason: "other", other: "Spelling canceled and cancellation is fun") }

    let(:detail) do
      create(:ramp_election,
             veteran_file_number: "64205555",
             notice_date: 5.days.ago,
             option_selected: "supplemental_claim",
             receipt_date: 3.days.ago)
    end

    it "cancels and clears detail values" do
      subject

      expect(intake.reload).to be_canceled
      expect(intake).to have_attributes(
        cancel_reason: "other",
        cancel_other: "Spelling canceled and cancellation is fun"
      )
      expect(detail.reload).to have_attributes(
        option_selected: nil,
        receipt_date: nil
      )
    end

    context "when already complete" do
      let(:completed_at) { 2.seconds.ago }

      it "returns and does nothing" do
        expect(intake).to_not be_persisted
        expect(intake).to_not be_canceled
        expect(intake).to have_attributes(
          cancel_reason: nil,
          cancel_other: nil
        )
        expect(detail.reload).to have_attributes(
          option_selected: "supplemental_claim",
          receipt_date: 3.days.ago.to_date
        )
      end
    end

    context "when completion is pending" do
      let(:completion_status) { "pending" }

      it "returns and does nothing" do
        expect(intake).to_not be_persisted
        expect(intake).to_not be_canceled
        expect(intake).to have_attributes(
          cancel_reason: nil,
          cancel_other: nil
        )
        expect(detail.reload).to have_attributes(
          option_selected: "supplemental_claim",
          receipt_date: 3.days.ago.to_date
        )
      end
    end
  end

  context "#complete!" do
    subject { intake.complete!({}) }

    let(:detail) do
      create(:ramp_election,
             veteran_file_number: "64205555",
             notice_date: 5.days.ago,
             option_selected: "supplemental_claim",
             receipt_date: 3.days.ago)
    end

    let!(:appeals_to_close) do
      (1..2).map do
        create(:legacy_appeal,
               vacols_case: create(
                 :case,
                 :status_advance,
                 bfcorlid: "64205555C",
                 bfdnod: 1.year.ago
               ))
      end
    end

    it "closes out the appeals correctly and creates an end product" do
      expect(Fakes::VBMSService).to receive(:establish_claim!).and_call_original

      expect(AppealRepository).to receive(:close_undecided_appeal!).with(
        appeal: appeals_to_close.first,
        user: intake.user,
        closed_on: Time.zone.today,
        disposition_code: "P"
      )

      expect(AppealRepository).to receive(:close_undecided_appeal!).with(
        appeal: appeals_to_close.last,
        user: intake.user,
        closed_on: Time.zone.today,
        disposition_code: "P"
      )

      subject

      expect(intake.reload).to be_success
      expect(intake.detail.established_at).to_not be_nil

      expect(
        RampClosedAppeal.where(
          vacols_id: appeals_to_close.first.vacols_id,
          ramp_election_id: detail.id,
          nod_date: appeals_to_close.first.nod_date
        )
      ).to_not be_nil

      expect(
        RampClosedAppeal.where(
          vacols_id: appeals_to_close.last.vacols_id,
          ramp_election_id: detail.id,
          nod_date: appeals_to_close.last.nod_date
        )
      ).to_not be_nil
    end

    describe "if there is already an existing and matching EP" do
      let!(:matching_ep) do
        Generators::EndProduct.build(
          veteran_file_number: veteran_file_number,
          bgs_attrs: {
            claim_type_code: "683SCRRRAMP",
            claim_receive_date: detail.receipt_date.to_formatted_s(:short_date),
            end_product_type_code: "683"
          }
        )
      end

      it "should return 'connected' with an error" do
        subject

        expect(intake.reload).to be_success
        expect(intake.error_code).to eq("connected_preexisting_ep")
        expect(detail.end_product_reference_id).to eq(matching_ep.claim_id)
      end
    end

    describe "if there are existing ramp elections" do
      let(:existing_option_selected) { "supplemental_claim" }
      let(:status_type_code) { "PEND" }

      let!(:existing_ramp_election) do
        create(:ramp_election,
               veteran_file_number: veteran_file_number,
               notice_date: 40.days.ago,
               option_selected: existing_option_selected,
               receipt_date: 38.days.ago,
               established_at: 38.days.ago,
               end_product_reference_id: preexisting_ep.claim_id)
      end

      let(:preexisting_ep) do
        Generators::EndProduct.build(
          veteran_file_number: veteran_file_number,
          bgs_attrs: {
            claim_type_code: "683SCRRRAMP",
            claim_receive_date: 38.days.ago.to_formatted_s(:short_date),
            status_type_code: status_type_code,
            end_product_type_code: "683"
          }
        )
      end

      context "the existing RAMP election EP is active" do
        it "closes out legacy appeals and connects intake to the existing ramp election" do
          expect(AppealRepository).to receive(:close_undecided_appeal!).with(
            appeal: appeals_to_close.first,
            user: intake.user,
            closed_on: Time.zone.today,
            disposition_code: "P"
          )

          expect(AppealRepository).to receive(:close_undecided_appeal!).with(
            appeal: appeals_to_close.last,
            user: intake.user,
            closed_on: Time.zone.today,
            disposition_code: "P"
          )

          subject

          expect(
            RampClosedAppeal.where(
              vacols_id: appeals_to_close.first.vacols_id,
              ramp_election_id: existing_ramp_election.id,
              nod_date: appeals_to_close.first.nod_date
            )
          ).to_not be_nil

          expect(
            RampClosedAppeal.where(
              vacols_id: appeals_to_close.last.vacols_id,
              ramp_election_id: existing_ramp_election.id,
              nod_date: appeals_to_close.last.nod_date
            )
          ).to_not be_nil

          expect { detail.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "the existing RAMP election EP is inactive" do
        let(:status_type_code) { "CAN" }

        it "establishes new ramp election" do
          subject

          expect(intake.reload).to be_success
          expect(intake.detail).to_not eq(existing_ramp_election)
          expect(intake.detail.established_at).to_not be_nil
        end
      end

      context "exiting RAMP election EP is a different type" do
        let(:existing_option_selected) { "higher_level_review" }

        it "establishes new ramp election" do
          subject

          expect(intake.reload).to be_success
          expect(intake.detail).to_not eq(existing_ramp_election)
          expect(intake.detail.established_at).to_not be_nil
        end
      end
    end

    context "if VACOLS closure fails" do
      it "does not complete" do
        intake.save!
        expect(AppealRepository).to receive(:close_undecided_appeal!).and_raise("VACOLS failz")

        expect { subject }.to raise_error("VACOLS failz")

        intake.reload
        expect(intake.completed_at).to be_nil
      end
    end

    context "if end product creation fails" do
      let(:unknown_error) do
        Caseflow::Error::EstablishClaimFailedInVBMS.new("error")
      end

      it "clears pending status" do
        allow_any_instance_of(RampReview).to receive(:create_or_connect_end_product!).and_raise(unknown_error)

        expect { subject }.to raise_exception
        expect(intake.completion_status).to be_nil
      end
    end
  end

  context "#serialized_appeal_issues" do
    subject { intake.serialized_appeal_issues }

    let(:test_issue) do
      create(:case_issue,
             issprog: "02",
             isscode: "15",
             isslev1: "03",
             isslev2: "5257",
             issdesc: "Broken knee")
    end

    let!(:appeals) do
      [
        create(
          :legacy_appeal,
          vacols_case: create(
            :case,
            :status_advance,
            bfcorlid: "64205555C",
            case_issues: [
              create(:case_issue,
                     issprog: "02",
                     isscode: "15",
                     isslev1: "03",
                     isslev2: "5252",
                     issdesc: "Broken thigh"),
              test_issue
            ]
          )
        ),
        create(
          :legacy_appeal,
          vacols_case: create(
            :case,
            :status_advance,
            bfcorlid: "64205555C",
            case_issues: [
              create(:case_issue,
                     issprog: "02",
                     isscode: "15",
                     isslev1: "03",
                     isslev2: "5325",
                     issdesc: "")
            ]
          )
        )
      ]
    end

    it do
      is_expected.to eq([
                          {
                            id: appeals.first.id,
                            issues: [{
                              program_description: "02 - Compensation",
                              description: [
                                "15 - Service connection",
                                "03 - All Others",
                                "5252 - Thigh, limitation of flexion of"
                              ],
                              note: "Broken thigh"
                            }, {
                              program_description: "02 - Compensation",
                              description: [
                                "15 - Service connection",
                                "03 - All Others",
                                "5257 - Knee, other impairment of"
                              ],
                              note: "Broken knee"
                            }]
                          },
                          {
                            id: appeals.last.id,
                            issues: [{
                              program_description: "02 - Compensation",
                              description: [
                                "15 - Service connection",
                                "03 - All Others",
                                "5325 - Muscle injury, facial muscles"
                              ],
                              note: nil
                            }]
                          }
                        ])
    end
  end

  context "#start!" do
    subject { intake.start! }
    let!(:ramp_appeal) { vacols_case }

    context "not valid to start" do
      let(:veteran_file_number) { "NOTVALID" }

      it "does not save intake and returns false" do
        expect(subject).to be_falsey

        expect(intake).to have_attributes(
          started_at: Time.zone.now,
          completed_at: Time.zone.now,
          completion_status: "error",
          error_code: "invalid_file_number",
          detail: nil
        )
      end
    end

    context "valid to start" do
      context "RAMP election with notice_date exists" do
        let!(:ramp_election) do
          create(:ramp_election, veteran_file_number: "64205555", notice_date: 5.days.ago)
        end
        let(:new_ramp_election) { RampElection.where(veteran_file_number: "64205555").last }

        it "saves intake and sets detail to a new ramp election" do
          expect(subject).to be_truthy

          expect(intake.started_at).to eq(Time.zone.now)
          expect(intake.detail).to eq(new_ramp_election)
          expect(new_ramp_election).to_not be_nil
          expect(new_ramp_election.notice_date).to be_nil
        end
      end

      context "matching RAMP election does not exist" do
        let(:ramp_election) { RampElection.where(veteran_file_number: "64205555").first }

        it "creates a new RAMP election with no notice_date" do
          expect(subject).to be_truthy

          expect(ramp_election).to_not be_nil
          expect(ramp_election.notice_date).to be_nil
        end
      end

      context "intake is already in progress" do
        it "should not create another intake" do
          RampElectionIntake.new(
            user: user,
            veteran_file_number: veteran_file_number
          ).start!

          expect(intake).to_not be_nil
          expect(subject).to eq(false)
        end
      end
    end
  end

  context "#validate_start" do
    subject { intake.validate_start }
    let(:end_product_reference_id) { nil }
    let(:established_at) { nil }
    let!(:ramp_appeal) { vacols_case }
    let!(:ramp_election) do
      create(:ramp_election,
             veteran_file_number: "64205555",
             notice_date: 6.days.ago,
             end_product_reference_id: end_product_reference_id,
             established_at: established_at)
    end
    let(:new_ramp_election) { RampElection.where(veteran_file_number: "64205555").last }

    let(:education_issue) { create(:case_issue, :education) }

    context "the ramp election is complete" do
      let(:end_product_reference_id) { 1 }
      let(:established_at) { Time.zone.now }

      it "returns true even if there is an existing ramp election" do
        expect(subject).to eq(true)
      end
    end

    context "there are no active appeals" do
      let(:case_status) { :status_complete }

      it "adds no_active_appeals and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("no_active_appeals")
      end
    end

    context "there are no active compensation appeals" do
      let(:issues) { [education_issue] }

      it "adds no_active_compensation_appeals and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("no_active_compensation_appeals")
      end
    end

    context "there are no active fully compensation appeals" do
      let(:issues) { [compensation_issue, education_issue] }

      it "adds no_active_fully_compensation_appeals and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("no_active_fully_compensation_appeals")
      end
    end

    context "there are active but not eligible appeals" do
      let(:case_status) { :status_active }

      it "adds no_eligible_appeals and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("no_eligible_appeals")
      end
    end

    context "there are eligible appeals" do
      it { is_expected.to eq(true) }
    end
  end
end
