# frozen_string_literal: true

require "rails_helper"

describe BulkTaskAssignment do
  describe "#process" do
    let(:organization) { HearingsManagement.singleton }
    let!(:schedule_hearing1) do
      FactoryBot.create(
        :no_show_hearing_task, 
        assigned_to: organization, 
        created_at: 5.days.ago)
    end
    let!(:schedule_hearing2) do
      FactoryBot.create(:no_show_hearing_task, 
        assigned_to: organization, 
        created_at: 2.days.ago)
    end
    let!(:schedule_hearing3) do
      FactoryBot.create(:no_show_hearing_task, 
        assigned_to: organization, 
        created_at: 1.days.ago)
    end

    let(:assigned_to) { create(:user) }
    let(:assigned_by) { create(:user) }

    let(:params) do 
      {
        assigned_to_id: assigned_to.id, 
        assigned_by: assigned_by, 
        organization_id: organization_id, 
        task_type: task_type, 
        task_count: task_count
      }
    end
    let(:task_type) { "NoShowHearingTask" }
    let(:organization_id) { organization.id }
    let(:task_count) { 2 }

    context "when assigned to user does not belong to organization" do
      it "does not bulk assigns tasks" do
        organization.users << assigned_by
        bulk_assignment = BulkTaskAssignment.new(params)
        expect(bulk_assignment.valid?).to eq false
        error = ["does not belong to organization with id #{organization.id}"]
        expect(bulk_assignment.errors[:assigned_to]).to eq error
      end
    end

    context "when task type is not valid" do
      let(:task_type) { "UnknownTaskType" }

      it "does not bulk assigns tasks" do
        organization.users << assigned_by
        organization.users << assigned_to
        bulk_assignment = BulkTaskAssignment.new(params)
        expect(bulk_assignment.valid?).to eq false
        error = ["#{task_type} is not a valid task type"]
        expect(bulk_assignment.errors[:task_type]).to eq error
      end
    end

    context "when organization is not valid" do
      let(:organization_id) { 1234 }

      it "does not bulk assigns tasks" do
        organization.users << assigned_by
        organization.users << assigned_to
        bulk_assignment = BulkTaskAssignment.new(params)
        expect(bulk_assignment.valid?).to eq false
        error = ["could not find an organization with id #{organization_id}"]
        expect(bulk_assignment.errors[:organization_id]).to eq error
      end
    end

    context "when organization cannot bulk assign" do
      let(:organization_id) { create(:organization).id }

      it "does not bulk assigns tasks" do
        organization.users << assigned_by
        organization.users << assigned_to
        bulk_assignment = BulkTaskAssignment.new(params)
        expect(bulk_assignment.valid?).to eq false
        error = ["with id #{organization_id} cannot bulk assign tasks"]
        expect(bulk_assignment.errors[:organization]).to eq error
      end
    end


    context "when assigned by user does not belong to organization" do
      it "does not bulk assigns tasks" do
        organization.users << assigned_to
        bulk_assignment = BulkTaskAssignment.new(params)
        expect(bulk_assignment.valid?).to eq false
        error = ["does not belong to organization with id #{organization.id}"]
        expect(bulk_assignment.errors[:assigned_by]).to eq error
      end
    end

    context "when all attributes are present" do
      it "bulk assigns tasks" do
        organization.users << assigned_to
        organization.users << assigned_by
        count_before = Task.count
        bulk_assignment = BulkTaskAssignment.new(params)
        expect(bulk_assignment.valid?).to eq true
        result = bulk_assignment.process
        expect(Task.count).to eq count_before + 2
        expect(result.count).to eq 2
        expect(result.first.assigned_to).to eq assigned_to
        expect(result.first.type).to eq "NoShowHearingTask"
        expect(result.first.assigned_by).to eq assigned_by
        expect(result.first.appeal).to eq schedule_hearing1.appeal
        expect(result.first.parent_id).to eq schedule_hearing1.id
      end
    end
  end
end