# frozen_string_literal: true

RSpec.feature "Judge queue", :all_dbs do
  let(:judge) { create(:user) }
  let!(:vacols_judge) { create(:staff, :judge_role, user: judge) }

  let(:attorney) { create(:user) }
  let!(:vacols_attorney) { create(:staff, :attorney_role, user: attorney) }

  let!(:judge_team) do
    JudgeTeam.create_for_judge(judge).tap { |jt| jt.add_user(attorney) }
  end

  let(:root_task) { create(:root_task, appeal: appeal) }

  before do
    User.authenticate!(user: judge)
    FeatureToggle.enable!(:judge_queue_tabs)
  end
  after { FeatureToggle.disable!(:judge_queue_tabs) }

  describe "judge tabs display" do
    context "with assigned case" do
      let(:appeal) { create(:appeal) }
      let(:root_task) { create(:root_task, appeal: appeal) }
      let(:judge_task) do
        create(
          :ama_judge_decision_review_task,
          appeal: appeal,
          assigned_to: judge,
          parent: root_task
        )
      end

      it "displays all three judge's tabs" do
        visit("/queue")
        expect(page).to have_content(COPY::QUEUE_PAGE_ASSIGNED_TAB_TITLE, 1)
        expect(page).to have_content(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE, 0)
        expect(page).to have_content(COPY::QUEUE_PAGE_COMPLETE_TAB_TITLE)
      end
    end

    context "with on-hold tasks" do
      let!(:judge_active_tasks) { create_list(:ama_task, 2, :assigned, assigned_to: judge) }
      let!(:judge_onhold_tasks) { create_list(:ama_task, 4, :assigned, assigned_to: judge) }

      before do
        judge_onhold_tasks.each { |task| task.update!(status: Constants.TASK_STATUSES.on_hold) }
      end

      it "displays on-hold tasks" do
        visit("/queue")
        find("button", text: format(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE, 4)).click
        expect(find("tbody").find_all("tr").length).to eq(4)
      end
    end

    context "with 3 completed tasks" do
      let!(:judge_active_tasks) { create_list(:ama_task, 4, :assigned, assigned_to: judge) }
      let!(:judge_closed_tasks) { create_list(:ama_task, 3, :assigned, assigned_to: judge) }

      before do
        judge_closed_tasks.each { |task| task.update!(status: Constants.TASK_STATUSES.completed) }
      end

      it "displays completed tasks" do
        visit("/queue")
        find("button", text: format(COPY::QUEUE_PAGE_COMPLETE_TAB_TITLE)).click
        expect(find("tbody").find_all("tr").length).to eq(3)
      end
    end
  end
end
