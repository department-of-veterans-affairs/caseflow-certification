# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

describe AttorneyTask, :all_dbs do
  let!(:attorney) { create(:user) }
  let!(:judge) { create(:user) }
  let!(:attorney_staff) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }
  let!(:judge_staff) { create(:staff, :judge_role, sdomainid: judge.css_id) }
  let(:appeal) { create(:appeal) }
  let!(:parent) do
    create(:ama_judge_decision_review_task, assigned_by: judge, appeal: appeal, parent: appeal.root_task)
  end

  context ".create" do
    subject do
      AttorneyTask.create(
        assigned_to: attorney,
        assigned_by: judge,
        appeal: appeal,
        parent: parent
      )
    end

    it "returns the correct label" do
      expect(AttorneyTask.new.label).to eq(
        COPY::ATTORNEY_TASK_LABEL
      )
    end

    context "there are no sibling tasks" do
      it "is valid" do
        expect(subject.valid?).to eq true
      end
    end

    context "there is a completed sibling task" do
      before do
        create(:ama_attorney_task,
               :completed,
               assigned_to: attorney,
               assigned_by: judge,
               appeal: appeal,
               parent: parent)
      end

      it "is valid" do
        expect(subject.valid?).to eq true
      end
    end

    context "there is an uncompleted sibling task" do
      before do
        create(
          :ama_attorney_task,
          assigned_to: attorney,
          assigned_by: judge,
          appeal: appeal,
          parent: parent
        )
      end

      it "is not valid" do
        expect(subject.valid?).to eq false
        expect(subject.errors.messages[:parent].first).to eq "has open child tasks"
      end
    end
  end

  context ".available_actions" do
    let(:task) do
      AttorneyTask.create(
        assigned_to: attorney,
        assigned_by: judge,
        appeal: appeal,
        parent: parent,
        status: Constants.TASK_STATUSES.assigned
      )
    end

    subject { task.available_actions(attorney) }

    it "does not include the ability to place task on hold" do
      expect(subject).to_not include(Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h)
    end

    it "includes actions to submit decision draft, create admin action, and cancel task" do
      expected_actions = [
        Constants.TASK_ACTIONS.REVIEW_DECISION_DRAFT.to_h,
        Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]

      expect(subject).to eq(expected_actions)
    end
  end

  context "when cancelling the task" do
    let!(:attorney_task) { create(:ama_attorney_task, assigned_by: judge, appeal: appeal, parent: parent) }

    subject { attorney_task.update!(status: Constants.TASK_STATUSES.cancelled) }

    it "cancels the parent decision task and opens a judge assignment task" do
      expect(subject).to be true
      expect(attorney_task.reload.status).to eq Constants.TASK_STATUSES.cancelled
      expect(parent.reload.status).to eq Constants.TASK_STATUSES.cancelled
      assign_task = appeal.tasks.find_by(type: JudgeAssignTask.name)
      expect(assign_task.status).to eq Constants.TASK_STATUSES.assigned
      expect(assign_task.assigned_to).to eq judge
    end
  end
end
