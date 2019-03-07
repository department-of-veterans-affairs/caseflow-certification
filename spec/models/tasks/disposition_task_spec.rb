# frozen_string_literal: true

describe DispositionTask do
  describe ".create_disposition_task!" do
    let(:appeal) { FactoryBot.create(:appeal) }
    let(:parent) { nil }
    let!(:hearing) { FactoryBot.create(:hearing, appeal: appeal) }

    subject { described_class.create_disposition_task!(appeal, parent, hearing) }

    context "parent is a HearingTask" do
      let(:parent) { FactoryBot.create(:hearing_task, appeal: appeal) }

      it "creates a DispositionTask and a HearingTaskAssociation" do
        expect(DispositionTask.all.count).to eq 0
        expect(HearingTaskAssociation.all.count).to eq 0

        subject

        expect(DispositionTask.all.count).to eq 1
        expect(DispositionTask.first.appeal).to eq appeal
        expect(DispositionTask.first.parent).to eq parent
        expect(DispositionTask.first.assigned_to).to eq Bva.singleton
        expect(HearingTaskAssociation.all.count).to eq 1
        expect(HearingTaskAssociation.first.hearing).to eq hearing
        expect(HearingTaskAssociation.first.hearing_task).to eq parent
      end
    end

    context "parent is a RootTask" do
      let(:parent) { FactoryBot.create(:root_task, appeal: appeal) }

      it "should throw an error" do
        expect { subject }.to raise_error(Caseflow::Error::InvalidParentTask)
      end
    end
  end

  describe ".cancel!" do
    let(:disposition) { nil }
    let(:appeal) { FactoryBot.create(:appeal) }
    let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
    let!(:hearing_task) { FactoryBot.create(:hearing_task, parent: root_task, appeal: appeal) }
    let!(:hearing) { FactoryBot.create(:hearing, appeal: appeal, disposition: disposition) }
    let!(:disposition_task) do
      FactoryBot.create(
        :ama_disposition_task,
        parent: hearing_task,
        appeal: appeal,
        status: Constants.TASK_STATUSES.in_progress
      )
    end
    let!(:hearing_task_association) do
      FactoryBot.create(
        :hearing_task_association,
        hearing: hearing,
        hearing_task: hearing_task
      )
    end

    subject { disposition_task.cancel! }

    context "the appeal is an AMA appeal" do
      context "the task's hearing's disposition is canceled" do
        let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.cancelled }

        it "cancels the disposition task" do
          expect(disposition_task.cancelled?).to be_falsey
          expect(hearing_task.on_hold?).to be_truthy

          expect { subject }.to_not raise_error

          expect(disposition_task.cancelled?).to be_truthy
          expect(hearing_task.cancelled?).to be_truthy
          expect(InformalHearingPresentationTask.where(appeal: appeal).length).to eq 0
        end

        context "the appeal has a VSO" do
          let(:participant_id_with_pva) { "000000" }
          let!(:appeal) do
            create(:appeal, claimants: [create(:claimant, participant_id: participant_id_with_pva)])
          end

          before do
            Vso.create(
              name: "Paralyzed Veterans Of America",
              role: "VSO",
              url: "paralyzed-veterans-of-america",
              participant_id: "2452383"
            )

            allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids)
              .with([participant_id_with_pva]).and_return(
                participant_id_with_pva => {
                  representative_name: "PARALYZED VETERANS OF AMERICA, INC.",
                  representative_type: "POA National Organization",
                  participant_id: "2452383"
                }
              )
          end

          it "creates an IHP task" do
            expect(InformalHearingPresentationTask.where(appeal: appeal).length).to eq 0

            subject

            expect(InformalHearingPresentationTask.where(appeal: appeal).length).to eq 1
          end
        end
      end

      context "the task's hearing's disposition is not canceled" do
        let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.postponed }

        it "raises an error" do
          expect(disposition_task.cancelled?).to be_falsey
          expect { subject }.to raise_error(DispositionTask::HearingDispositionNotCanceled)
          expect(disposition_task.cancelled?).to be_falsey
        end
      end
    end

    context "the appeal is a legacy appeal" do
      let(:vacols_case) { FactoryBot.create(:case, bfcurloc: LegacyAppeal::LOCATION_CODES[:schedule_hearing]) }
      let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
      let(:hearing) { create(:legacy_hearing, appeal: appeal, disposition: disposition) }
      let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.cancelled }

      context "there's no associated VSO" do
        it "updates the case location to case storage (81)" do
          subject

          expect(vacols_case.reload.bfcurloc).to eq(LegacyAppeal::LOCATION_CODES[:case_storage])
        end
      end

      context "there is an associated VSO" do
        let(:participant_id) { "1234" }
        let!(:vso) { create(:vso, name: "Gogozim", participant_id: participant_id) }

        before do
          allow(BGSService).to receive(:power_of_attorney_records).and_return(
            appeal.veteran_file_number => {
              file_number: appeal.veteran_file_number,
              power_of_attorney: {
                legacy_poa_cd: "3QQ",
                nm: "Clarence Darrow",
                org_type_nm: "POA Attorney",
                ptcpnt_id: participant_id
              }
            }
          )
        end

        it "updates the case location to service organization (55)" do
          subject

          expect(vacols_case.reload.bfcurloc).to eq(LegacyAppeal::LOCATION_CODES[:service_organization])
        end
      end
    end
  end
end
