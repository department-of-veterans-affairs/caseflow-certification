# frozen_string_literal: true

require "rails_helper"

describe HearingDispositionChangeJob do
  def create_disposition_task_ancestry(disposition: nil, scheduled_for: nil, associated_hearing: true)
    appeal = FactoryBot.create(:appeal)
    root_task = FactoryBot.create(:root_task, appeal: appeal)
    distribution_task = FactoryBot.create(:distribution_task, appeal: appeal, parent: root_task)
    parent_hearing_task = FactoryBot.create(:hearing_task, appeal: appeal, parent: distribution_task)

    hearing = FactoryBot.create(:hearing, appeal: appeal, disposition: disposition)
    if scheduled_for
      hearing = FactoryBot.create(
        :hearing,
        appeal: appeal,
        disposition: disposition,
        scheduled_time: scheduled_for
      )
      hearing_day = FactoryBot.create(:hearing_day, scheduled_for: scheduled_for)
      hearing.update!(hearing_day: hearing_day)
    end

    HearingTaskAssociation.create!(hearing: hearing, hearing_task: parent_hearing_task) if associated_hearing
    DispositionTask.create!(appeal: appeal, parent: parent_hearing_task, assigned_to: Bva.singleton)
  end

  describe ".modify_task_by_dispisition" do
    subject { HearingDispositionChangeJob.new.modify_task_by_dispisition(task) }

    context "when hearing has a disposition" do
      let(:task) { create_disposition_task_ancestry(disposition: disposition) }

      context "when disposition is held" do
        let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.held }
        it "returns a label matching the hearing disposition and call DispositionTask.hold!" do
          expect(task).to receive(:hold!).exactly(1).times
          expect(subject).to eq(disposition)
        end
      end

      context "when disposition is cancelled" do
        let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.cancelled }
        it "returns a label matching the hearing disposition and call DispositionTask.cancel!" do
          expect(task).to receive(:cancel!).exactly(1).times
          expect(subject).to eq(disposition)
        end
      end

      context "when disposition is postponed" do
        let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.postponed }
        it "returns a label matching the hearing disposition and not change the task" do
          attributes_before = task.attributes
          expect(subject).to eq(disposition)
          expect(task.attributes).to eq(attributes_before)
        end
      end

      context "when disposition is no_show" do
        let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.no_show }
        it "returns a label matching the hearing disposition and call DispositionTask.no_show!" do
          expect(task).to receive(:no_show!).exactly(1).times
          expect(subject).to eq(disposition)
        end
      end

      context "when the disposition is not an expected disposition" do
        let(:disposition) { "FAKE_DISPOSITION" }
        it "returns a label indicating that the hearing disposition is unknown and not change the task" do
          attributes_before = task.attributes
          expect(subject).to eq(:unknown_disposition)
          expect(task.attributes).to eq(attributes_before)
        end
      end
    end

    context "when hearing has no disposition" do
      let(:task) { create_disposition_task_ancestry(disposition: nil, scheduled_for: scheduled_for) }

      context "when hearing was scheduled to take place more than 2 days ago" do
        let(:scheduled_for) { 3.days.ago }

        it "returns a label indicating that the hearing is stale and does not change the task" do
          attributes_before = task.attributes
          expect(subject).to eq(:stale)
          expect(task.attributes).to eq(attributes_before)
        end
      end

      context "when hearing was scheduled to take place less than 2 days ago" do
        let(:scheduled_for) { 25.hours.ago }

        it "returns a label indicating that the hearing was recently held and does not change the task" do
          attributes_before = task.attributes
          expect(subject).to eq(:between_one_and_two_days_old)
          expect(task.attributes).to eq(attributes_before)
        end
      end
    end
  end

  describe ".log_info" do
    let(:start_time) { 5.minutes.ago }
    let(:task_count_for) { {} }
    let(:error_count) { 0 }
    let(:hearing_ids) { [] }
    let(:error) { nil }

    context "when the job runs successfully" do
      it "logs and sends the correct message to slack" do
        slack_msg = ""
        allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

        expect(Rails.logger).to receive(:info).exactly(2).times

        HearingDispositionChangeJob.new.log_info(start_time, task_count_for, error_count, hearing_ids, error)

        expected_msg = "HearingDispositionChangeJob completed after running for .*." \
          " Encountered errors for #{error_count} hearings."
        expect(slack_msg).to match(/#{expected_msg}/)
      end
    end

    context "when there is are elements in the input task_count_for hash" do
      let(:task_count_for) { { first_key: 0, second_key: 13 } }

      it "includes a sentence in the output message for each element of the hash" do
        slack_msg = ""
        allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

        HearingDispositionChangeJob.new.log_info(start_time, task_count_for, error_count, hearing_ids, error)

        expected_msg = "HearingDispositionChangeJob completed after running for .*." \
          " Processed 0 First key hearings." \
          " Processed 13 Second key hearings." \
          " Encountered errors for #{error_count} hearings."
        expect(slack_msg).to match(/#{expected_msg}/)
      end
    end

    context "when the job encounters a fatal error" do
      let(:err_msg) { "Example error text" }
      # Throw and then catch the error so it has a stack trace.
      let(:error) do
        fail StandardError, err_msg
      rescue StandardError => e
        e
      end

      it "logs an error message and sends the correct message to slack" do
        slack_msg = ""
        allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

        expect(Rails.logger).to receive(:info).exactly(3).times

        HearingDispositionChangeJob.new.log_info(start_time, task_count_for, error_count, hearing_ids, error)

        expected_msg = "HearingDispositionChangeJob failed after running for .*." \
          " Encountered errors for #{error_count} hearings. Fatal error: #{err_msg}"
        expect(slack_msg).to match(/#{expected_msg}/)
      end
    end
  end

  describe ".perform" do
    subject { HearingDispositionChangeJob.new.perform }

    context "when there is an error outside of the loop" do
      let(:error_msg) { "FAKE ERROR MESSAGE HERE" }

      before { allow(DispositionTask).to receive(:ready_for_action).and_raise(error_msg) }

      it "sends the correct number of arguments to log_info" do
        args = Array.new(5, anything)
        expect_any_instance_of(HearingDispositionChangeJob).to receive(:log_info).with(*args).exactly(1).times
        subject
      end
    end

    context "when the job runs successfully" do
      let(:not_ready_for_action_count) { 4 }
      let(:error_count) { 13 }
      let(:task_count_for_dispositions) do
        {
          Constants.HEARING_DISPOSITION_TYPES.held => 8,
          Constants.HEARING_DISPOSITION_TYPES.cancelled => 2,
          Constants.HEARING_DISPOSITION_TYPES.postponed => 3,
          Constants.HEARING_DISPOSITION_TYPES.no_show => 5
        }
      end
      let(:task_count_for_others) do
        {
          between_one_and_two_days_old: 6,
          stale: 7,
          unknown_disposition: 1
        }
      end
      let(:task_count_for) { task_count_for_dispositions.merge(task_count_for_others) }

      before do
        not_ready_for_action_count.times do
          create_disposition_task_ancestry(
            disposition: Constants.HEARING_DISPOSITION_TYPES.held,
            scheduled_for: nil,
            associated_hearing: false
          )
        end

        ready_for_action_time = 36.hours.ago
        task_count_for_dispositions.each do |disposition, task_count|
          task_count.times do
            create_disposition_task_ancestry(
              disposition: disposition,
              scheduled_for: ready_for_action_time,
              associated_hearing: true
            )
          end
        end

        task_count_for_others[:between_one_and_two_days_old].times do
          create_disposition_task_ancestry(
            disposition: nil,
            scheduled_for: ready_for_action_time,
            associated_hearing: true
          )
        end

        task_count_for_others[:stale].times do
          create_disposition_task_ancestry(
            disposition: nil,
            scheduled_for: 5.days.ago,
            associated_hearing: true
          )
        end

        task_count_for_others[:unknown_disposition].times do
          create_disposition_task_ancestry(
            disposition: "FAKE_DISPOSITION",
            scheduled_for: ready_for_action_time,
            associated_hearing: true
          )
        end

        hearing_ids_to_error = Array.new(error_count) do
          create_disposition_task_ancestry(
            disposition: Constants.HEARING_DISPOSITION_TYPES.held,
            scheduled_for: ready_for_action_time,
            associated_hearing: true
          ).hearing.id
        end

        disposition_for_hearing = Hearing.all.map { |hearing| [hearing.id, hearing.disposition] }.to_h

        allow_any_instance_of(Hearing).to receive(:disposition) do |hearing|
          fail "FAKE ERROR MESSAGE" if hearing_ids_to_error.include?(hearing.id)

          disposition_for_hearing[hearing.id]
        end
      end

      it "sends the correct arguments to log_info" do
        expect_any_instance_of(HearingDispositionChangeJob).to(
          receive(:log_info).with(anything, task_count_for, error_count, anything).exactly(1).times
        )
        subject
      end
    end
  end
end
