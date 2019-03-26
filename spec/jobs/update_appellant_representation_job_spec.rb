# frozen_string_literal: true

require "rails_helper"

describe UpdateAppellantRepresentationJob do
  context "when the job runs successfully" do
    let(:new_task_count) { 3 }
    let(:closed_task_count) { 1 }
    let(:correct_task_count) { 6 }
    let(:error_count) { 0 }
    let(:vso_for_appeal) { {} }

    before do
      correct_task_count.times do |_|
        appeal, vso = create_appeal_and_vso
        FactoryBot.create(:track_veteran_task, appeal: appeal, assigned_to: vso)
        vso_for_appeal[appeal.id] = [vso]
      end

      new_task_count.times do |_|
        appeal, vso = create_appeal_and_vso
        vso_for_appeal[appeal.id] = [vso]
      end

      closed_task_count.times do |_|
        appeal, vso = create_appeal_and_vso
        FactoryBot.create(:track_veteran_task, appeal: appeal, assigned_to: vso)
        vso_for_appeal[appeal.id] = []
      end

      allow_any_instance_of(Appeal).to receive(:vsos) { |a| vso_for_appeal[a.id] }
    end

    it "runs the job as expected" do
      expect_any_instance_of(UpdateAppellantRepresentationJob).to receive(:log_info).with(
        anything,
        new_task_count,
        closed_task_count,
        error_count
      )

      UpdateAppellantRepresentationJob.perform_now
    end

    context "when there are legacy appeals with disposition task" do
      let(:legacy_task_count) { 10 }

      let(:legacy_appeals) do
        (1..legacy_task_count).map do |_|
          legacy_appeal = create(:legacy_appeal, vacols_case: create(:case))
          create(
            :disposition_task,
            appeal: legacy_appeal,
            assigned_to: HearingsManagement.singleton,
            parent: create(:hearing_task, appeal: legacy_appeal, assigned_to: HearingsManagement.singleton)
          )
          vso_for_appeal[legacy_appeal.id] = [create(:vso)]

          legacy_appeal
        end
      end

      it "updates every appeal", focus: true do
        UpdateAppellantRepresentationJob.perform_now

        legacy_appeals.each do |legacy_appeal|
          expect(legacy_appeal.reload.record_synced_by_job.first.processed?).to eq(true)
        end
      end
    end

    it "sends the correct message to Slack" do
      slack_msg = ""
      allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

      UpdateAppellantRepresentationJob.perform_now

      expected_msg = "UpdateAppellantRepresentationJob completed after running for .*." \
          " Created #{new_task_count} new tracking tasks and closed #{closed_task_count} existing tracking tasks." \
          " Encountered errors for #{error_count} individual appeals."
      expect(slack_msg).to match(/#{expected_msg}/)
    end
  end

  context "when individual appeals throw errors" do
    let(:new_task_count) { 3 }
    let(:closed_task_count) { 1 }
    let(:correct_task_count) { 6 }
    let(:error_count) { 2 }

    before do
      vso_for_appeal = {}

      correct_task_count.times do |_|
        appeal, vso = create_appeal_and_vso
        FactoryBot.create(:track_veteran_task, appeal: appeal, assigned_to: vso)
        vso_for_appeal[appeal.id] = [vso]
      end

      new_task_count.times do |_|
        appeal, vso = create_appeal_and_vso
        vso_for_appeal[appeal.id] = [vso]
      end

      closed_task_count.times do |_|
        appeal, vso = create_appeal_and_vso
        FactoryBot.create(:track_veteran_task, appeal: appeal, assigned_to: vso)
        vso_for_appeal[appeal.id] = []
      end

      error_indicator = "RAISE ERROR"
      error_count.times do |_|
        appeal, vso = create_appeal_and_vso
        FactoryBot.create(:track_veteran_task, appeal: appeal, assigned_to: vso)
        vso_for_appeal[appeal.id] = error_indicator
      end

      allow_any_instance_of(Appeal).to receive(:vsos) do |a|
        fail "No vsos for appeal ID #{a.id}" if error_indicator == vso_for_appeal[a.id]

        vso_for_appeal[a.id]
      end
    end

    it "the job still runs to completion" do
      expect_any_instance_of(UpdateAppellantRepresentationJob).to receive(:log_info).with(
        anything,
        new_task_count,
        closed_task_count,
        error_count
      )

      UpdateAppellantRepresentationJob.perform_now
    end

    it "message sent to Slack includes notice of failed appeals" do
      slack_msg = ""
      allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

      UpdateAppellantRepresentationJob.perform_now

      expected_msg = "UpdateAppellantRepresentationJob completed after running for .*." \
          " Created #{new_task_count} new tracking tasks and closed #{closed_task_count} existing tracking tasks." \
          " Encountered errors for #{error_count} individual appeals."
      expect(slack_msg).to match(/#{expected_msg}/)
    end
  end

  # context "when individual appeals throw errors" do
end

def create_appeal_and_vso
  appeal = FactoryBot.create(:appeal)
  FactoryBot.create(:root_task, appeal: appeal)
  vso = FactoryBot.create(:vso)

  [appeal, vso]
end
