# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tasks::EndHoldController, type: :controller do
  describe "POST tasks/:id/end_hold" do
    let(:user) { FactoryBot.create(:user) }
    let!(:parent) { FactoryBot.create(:generic_task) }
    let(:parent_id) { parent.id }
    let!(:timed_hold_task) do
      FactoryBot.create(:timed_hold_task, appeal: parent.appeal, assigned_to: user, days_on_hold: 18, parent: parent)
    end

    subject { post(:create, params: { task_id: parent_id }) }

    before do
      User.authenticate!(user: user)
    end

    context "with the correct parameters" do
      it "cancels the TimedHoldTask for the task" do
        expect(parent.status).to eq Constants.TASK_STATUSES.on_hold
        expect(parent.children.find_by(type: TimedHoldTask.name)).to eq timed_hold_task

        subject

        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)["tasks"]["data"]
        expect(response_body.length).to eq 2

        expect(parent.reload.status).to eq Constants.TASK_STATUSES.assigned
        expect(timed_hold_task.reload.status).to eq Constants.TASK_STATUSES.cancelled
      end
    end

    context "with a non-existent parent_id" do
      let(:parent_id) { parent.id + 999 }

      it "returns a not found error" do
        subject

        expect(response.status).to eq(404)
      end
    end

    context "when the user is missing" do
      before do
        user.destroy!
      end

      it "returns an invalid record error" do
        subject

        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)["errors"][0]["title"]).to eq "Record is invalid"
      end
    end
  end
end
