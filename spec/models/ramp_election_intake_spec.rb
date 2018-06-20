describe RampElectionIntake do
  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
  end

  let(:veteran_file_number) { "64205555" }
  let(:user) { Generators::User.build }
  let(:detail) { nil }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }
  let(:appeal_vacols_record) { :ready_to_certify }
  let(:compensation_issue) { Generators::Issue.build(template: :compensation) }
  let(:issues) { [compensation_issue] }
  let(:completed_at) { nil }

  let(:intake) do
    RampElectionIntake.new(
      user: user,
      detail: detail,
      veteran_file_number: veteran_file_number,
      completed_at: completed_at
    )
  end

  let(:appeal) do
    Generators::LegacyAppeal.build(
      vbms_id: "64205555C",
      vacols_record: appeal_vacols_record,
      veteran: veteran,
      issues: issues
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
        Generators::Appeal
          .create(vbms_id: "64205555C", vacols_record: { template: :ready_to_certify, nod_date: 1.year.ago })
      end
    end

    let(:first_appeal_attributes) do
      { vacols_id: appeals_to_close.first.vacols_id,
        ramp_election_id: former_detail.id,
        nod_date: appeals_to_close.first.nod_date }
    end

    let(:second_appeal_attributes) do
      { vacols_id: appeals_to_close.last.vacols_id,
        ramp_election_id: former_detail.id,
        nod_date: appeals_to_close.last.nod_date }
    end

    it "closes out the appeals correctly and creates an end product" do
      expect(Fakes::VBMSService).to receive(:establish_claim!).and_call_original

      expect(RampClosedAppeal).to receive(:new).with(
        vacols_id: appeals_to_close.first.vacols_id,
        ramp_election_id: detail.id,
        nod_date: appeals_to_close.first.nod_date
      ).and_call_original

      expect(RampClosedAppeal).to receive(:new).with(
        vacols_id: appeals_to_close.last.vacols_id,
        ramp_election_id: detail.id,
        nod_date: appeals_to_close.last.nod_date
      ).and_call_original

      expect(Fakes::AppealRepository).to receive(:close_undecided_appeal!).with(
        appeal: appeals_to_close.first,
        user: intake.user,
        closed_on: Time.zone.today,
        disposition_code: "P"
      )

      expect(Fakes::AppealRepository).to receive(:close_undecided_appeal!).with(
        appeal: appeals_to_close.last,
        user: intake.user,
        closed_on: Time.zone.today,
        disposition_code: "P"
      )

      subject

      expect(intake.reload).to be_success
      expect(intake.detail.established_at).to_not be_nil
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
      end
    end

    describe "if there are existing ramp elections" do
      let(:former_detail) do
        create(:ramp_election,
               veteran_file_number: veteran_file_number,
               notice_date: 40.days.ago,
               option_selected: "supplemental_claim",
               receipt_date: 38.days.ago,
               established_at: 38.days.ago)
      end
      let!(:former_intake) do
        RampElectionIntake.new(
          user: user,
          detail: former_detail,
          veteran_file_number: veteran_file_number,
          completed_at: 1.month.ago
        )
      end

      it "closes out legacy appeals and connects the existing EP to the ramp election" do
        expect(RampClosedAppeal).to receive(:new).with(first_appeal_attributes).and_call_original
        expect(RampClosedAppeal).to receive(:new).with(second_appeal_attributes).and_call_original

        expect(Fakes::AppealRepository).to receive(:close_undecided_appeal!).with(
          appeal: appeals_to_close.first,
          user: intake.user,
          closed_on: Time.zone.today,
          disposition_code: "P"
        )

        expect(Fakes::AppealRepository).to receive(:close_undecided_appeal!).with(
          appeal: appeals_to_close.last,
          user: intake.user,
          closed_on: Time.zone.today,
          disposition_code: "P"
        )

        subject

        expect(RampClosedAppeal.where(first_appeal_attributes)).to_not be_nil
        expect(RampClosedAppeal.where(second_appeal_attributes)).to_not be_nil
      end

      context "when an EP already exists" do
        let(:preexisting_ep) do
          Generators::EndProduct.build(
            veteran_file_number: "64205555",
            bgs_attrs: {
              claim_type_code: "683SCRRRAMP",
              claim_receive_date: intake.detail.receipt_date.to_formatted_s(:short_date),
              end_product_type_code: "683"
            }
          )
        end

        it "closes out legacy appeals and connects the existing EP to the ramp election" do
          subject

          expect(intake.reload).to be_success
          expect(intake.error_code).to be_nil
        end
      end

      it "connects the intake to the existing active ramp election of the same type" do
        subject

        expect(intake.reload).to be_success
        expect(intake.detail).to eq(former_detail)
      end

      it "doesn't connect a ramp election of a different type" do
        detail.update!(option_selected: "higher_level_review")

        subject

        expect(intake.reload).to be_success
        expect(intake.detail).to_not eq(former_detail)
        expect(intake.detail.established_at).to_not be_nil
      end

      it "doesn't connect to the ramp election without an active product" do
        Generators::EndProduct.build(
          veteran_file_number: veteran_file_number,
          bgs_attrs: {
            claim_type_code: "683SCRRRAMP",
            claim_receive_date: former_detail.receipt_date.to_formatted_s(:short_date),
            status_type_code: "CAN",
            end_product_type_code: "683"
          }
        )

        subject

        expect(intake.reload).to be_success
        expect(intake.error_code).to be_nil
      end

      it "destroys the temporary ramp election" do
        temporary_ramp_election_id = detail.id
        subject
        expect { RampElection.find(temporary_ramp_election_id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "if VACOLS closure fails" do
      it "does not complete" do
        intake.save!
        expect(Fakes::AppealRepository).to receive(:close_undecided_appeal!).and_raise("VACOLS failz")

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

    let!(:appeals) do
      [
        Generators::LegacyAppeal.create(
          vbms_id: "64205555C",
          issues: [
            Generators::Issue.build(note: "Broken thigh"),
            Generators::Issue.build(codes: %w[02 16 03 5252],
                                    labels: [
                                      "Compensation",
                                      "Something else",
                                      "All Others",
                                      "Knee, limitation of flexion of"
                                    ],
                                    note: "Broken knee")
          ]
        ),
        Generators::LegacyAppeal.create(
          vbms_id: "64205555C",
          issues: [
            Generators::Issue.build(codes: %w[02 15],
                                    labels: ["Compensation", "Last Issue"],
                                    note: "")
          ]
        )
      ]
    end

    it do
      is_expected.to eq([{
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
                              "16 - Something else",
                              "03 - All Others",
                              "5252 - Knee, limitation of flexion of"
                            ],
                            note: "Broken knee"
                          }]
                        },
                         {
                           id: appeals.last.id,
                           issues: [{
                             program_description: "02 - Compensation",
                             description: ["15 - Last Issue"],
                             note: ""
                           }]
                         }])
    end
  end

  context "#start!" do
    subject { intake.start! }
    let!(:ramp_appeal) { appeal }

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
          RampElection.create!(veteran_file_number: "64205555", notice_date: 5.days.ago)
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
    let!(:ramp_appeal) { appeal }
    let!(:ramp_election) do
      RampElection.create!(
        veteran_file_number: "64205555",
        notice_date: 6.days.ago,
        end_product_reference_id: end_product_reference_id,
        established_at: established_at
      )
    end
    let(:new_ramp_election) { RampElection.where(veteran_file_number: "64205555").last }

    let(:education_issue) { Generators::Issue.build(template: :education) }

    context "the ramp election is complete" do
      let(:end_product_reference_id) { 1 }
      let(:established_at) { Time.zone.now }

      it "returns true even if there is an existing ramp election" do
        expect(subject).to eq(true)
      end
    end

    context "there are no active appeals" do
      let(:appeal_vacols_record) { :full_grant_decided }

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
      let(:appeal_vacols_record) { :pending_hearing }

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
