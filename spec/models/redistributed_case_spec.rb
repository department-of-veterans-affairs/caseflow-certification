# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "support/database_cleaner"
require "rails_helper"

describe RedistributedCase, :all_dbs do
  let!(:vacols_case) { create(:case, bfcurloc: "CASEFLOW") }
  let(:judge) { create(:user) }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge.css_id) }
  let(:distribution) { Distribution.create!(judge: judge) }
  # legacy_appeal.vacols_id is set to legacy_appeal.case_record["bfkey"]
  subject { RedistributedCase.new(case_id: legacy_appeal.vacols_id, new_distribution: distribution) }

  context ".ok_to_redistribute?" do
    context "when there are no relevant tasks" do
      let(:legacy_appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
      it "returns true" do
        expect(subject.ok_to_redistribute?).to eq true
      end
    end
    context "when RootTask and TrackVeteranTask exist" do
      before do
        # TrackVeteranTask should be ignored by ok_to_redistribute?
        TrackVeteranTask.create!(appeal: legacy_appeal, assigned_to: create(:vso))
      end
      context "when there is an open ScheduleHearingTask and an open parent HearingTask" do
        let(:legacy_appeal) { create(:legacy_appeal, :with_schedule_hearing_tasks, vacols_case: vacols_case) }

        it "returns false" do
          expect(subject.ok_to_redistribute?).to eq false
        end
      end
      context "when there is an open ScheduleHearingTask and a cancelled parent HearingTask" do
        let(:legacy_appeal) { create(:legacy_appeal, :with_schedule_hearing_tasks, vacols_case: vacols_case) }
        before do
          legacy_appeal.tasks.where(type: :HearingTask).each do |t|
            t.update!(status: Constants.TASK_STATUSES.cancelled)
          end
        end
        it "returns false" do
          expect(subject.ok_to_redistribute?).to eq false
        end
      end
      context "when there is a cancelled ScheduleHearingTask, which causes a cancelled parent HearingTask" do
        let(:legacy_appeal) { create(:legacy_appeal, :with_schedule_hearing_tasks, vacols_case: vacols_case) }
        before do
          legacy_appeal.tasks.where(type: :ScheduleHearingTask).each do |t|
            t.update!(status: Constants.TASK_STATUSES.cancelled)
          end
        end
        it "returns true" do
          expect(subject.ok_to_redistribute?).to eq true
        end
      end
      context "when there is a completed ScheduleHearingTask, which causes a completed parent HearingTask" do
        let(:legacy_appeal) { create(:legacy_appeal, :with_schedule_hearing_tasks, vacols_case: vacols_case) }
        before do
          legacy_appeal.tasks.where(type: :ScheduleHearingTask).each do |t|
            t.update!(status: Constants.TASK_STATUSES.completed)
          end
        end
        it "returns true" do
          expect(subject.ok_to_redistribute?).to eq false
        end
      end
    end
  end
end
