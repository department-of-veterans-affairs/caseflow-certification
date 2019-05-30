# frozen_string_literal: true

require "rails_helper"
require "mail_task"

RSpec.feature "MailTasks" do
  let(:user) { FactoryBot.create(:user) }

  before do
    User.authenticate!(user: user)
  end

  describe "Assigning a mail team task to a team member" do
    context "when task is assigned to AOD team" do
      let(:root_task) { FactoryBot.create(:root_task) }

      let(:mail_team_task) do
        AodMotionMailTask.create!(
          appeal: root_task.appeal,
          parent_id: root_task.id,
          assigned_to: MailTeam.singleton
        )
      end

      let(:aod_team) { AodTeam.singleton }

      let(:aod_team_task) do
        AodMotionMailTask.create!(
          appeal: root_task.appeal,
          parent_id: mail_team_task.id,
          assigned_to: aod_team
        )
      end

      before do
        OrganizationsUser.add_user_to_organization(user, aod_team)
      end

      it "successfully assigns the task to team member" do
        visit("queue/appeals/#{aod_team_task.appeal.external_id}")

        prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
        text = Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.label
        click_dropdown(prompt: prompt, text: text)
        fill_in("taskInstructions", with: "instructions")
        click_button("Submit")

        expect(page).to have_content(format(COPY::ASSIGN_TASK_SUCCESS_MESSAGE, user.full_name))
        expect(page.current_path).to eq("/queue")

        new_tasks = aod_team_task.children
        expect(new_tasks.length).to eq(1)

        new_task = new_tasks.first
        expect(new_task.assigned_to).to eq(user)
      end
    end
  end

  describe "Changing a mail team task type" do
    context "when task does not need to be reassigned" do
      let(:root_task) { FactoryBot.create(:root_task) }
      let(:old_task_type) { DeathCertificateMailTask }
      let(:new_task_type) { AddressChangeMailTask }

      let!(:mail_task) do
        old_task_type.create!(
          appeal: root_task.appeal,
          parent_id: root_task.id,
          assigned_to: user
        )
      end

      before do
        OrganizationsUser.add_user_to_organization(user, Colocated.singleton)
      end

      it "should update the task type" do
        # Visit case details page
        visit "/queue"
        click_on "#{root_task.appeal.veteran_full_name} (#{root_task.appeal.veteran_file_number})"

        # Navigate to the change task type modal
        find(".Select-control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find("div", class: "Select-option", text: Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h[:label]).click

        expect(page).to have_content(COPY::CHANGE_TASK_TYPE_SUBHEAD)

        # Ensure all admin actions are available
        mail_tasks = MailTask.subclass_routing_options
        find(".Select-control", text: "Select an action type").click do
          visible_options = page.find_all(".Select-option")
          expect(visible_options.length).to eq mail_tasks.length
        end

        # Attempt to change task type without including instuctions.
        find("div", class: "Select-option", text: new_task_type.label).click
        find("button", text: COPY::CHANGE_TASK_TYPE_SUBHEAD).click

        # Instructions field is required
        expect(page).to have_content(COPY::FORM_ERROR_FIELD_REQUIRED)

        # Add instructions and try again
        instructions = generate_words(5)
        fill_in("instructions", with: instructions)
        find("button", text: COPY::CHANGE_TASK_TYPE_SUBHEAD).click

        # We should see a success message but remain on the case details page
        expect(page).to have_content(
          format(
            COPY::CHANGE_TASK_TYPE_CONFIRMATION_TITLE,
            old_task_type.label,
            new_task_type.label
          )
        )

        # Ensure the task has been updated and the assignee is unchanged
        expect(page).to have_content(format("TASK\n%<label>s", label: new_task_type.label))
        expect(page).to have_content(format("ASSIGNED TO\n%<css_id>s", css_id: user.css_id))
        click_on COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL
        expect(page).to have_content(instructions)
      end
    end

    context "when task does need to be reassigned" do
      let(:root_task) { FactoryBot.create(:root_task) }
      let(:old_task_type) { DeathCertificateMailTask }
      let(:new_task_type) { AodMotionMailTask }

      let!(:mail_task) do
        old_task_type.create!(
          appeal: root_task.appeal,
          parent_id: root_task.id,
          assigned_to: user
        )
      end

      it "should update the task type and assignee" do
        # Visit case details page
        visit "/queue"
        click_on "#{root_task.appeal.veteran_full_name} (#{root_task.appeal.veteran_file_number})"

        # Navigate to the change task type modal
        find(".Select-control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find("div", class: "Select-option", text: Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h[:label]).click

        expect(page).to have_content(COPY::CHANGE_TASK_TYPE_SUBHEAD)

        # Ensure all admin actions are available
        mail_tasks = MailTask.subclass_routing_options
        find(".Select-control", text: "Select an action type").click do
          visible_options = page.find_all(".Select-option")
          expect(visible_options.length).to eq mail_tasks.length
        end

        # Attempt to change task type without including instuctions.
        find("div", class: "Select-option", text: new_task_type.label).click
        find("button", text: COPY::CHANGE_TASK_TYPE_SUBHEAD).click

        # Instructions field is required
        expect(page).to have_content(COPY::FORM_ERROR_FIELD_REQUIRED)

        # Add instructions and try again
        instructions = generate_words(5)
        fill_in("instructions", with: instructions)
        find("button", text: COPY::CHANGE_TASK_TYPE_SUBHEAD).click

        # We should see a success message but remain on the case details page
        expect(page).to have_content(
          format(
            COPY::CHANGE_TASK_TYPE_CONFIRMATION_TITLE,
            old_task_type.label,
            new_task_type.label
          )
        )

        # Ensure the task has been updated
        expect(page).to have_content(format("TASK\n%<label>s", label: new_task_type.label))
        expect(page).to have_content(format("ASSIGNED TO\n%<name>s", name: AodTeam.singleton.name))
        # Cancelled task is showing up in timeline. is this intended? should the instructions be
        #   showing up as well?
        # click_on COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL
        find_all("#currently-active-tasks button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
        expect(page).to have_content(instructions)
      end
    end
  end
end
