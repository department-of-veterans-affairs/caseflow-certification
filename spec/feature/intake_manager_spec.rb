require "rails_helper"

RSpec.feature "Intake Manager Page" do
  before do
    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2017, 8, 8))
  end

  context "As a user with Admin Intake role", :focus => true do
    let!(:current_user) do
      User.authenticate!(roles: ["Admin Intake"])
    end

    scenario "Has access to intake manager page" do
      visit "/intake/manager"
      expect(page).to have_content("Claims for manager review")
      expect(page).to have_content("Veteran File Number")
      expect(page).to have_content("Date Processed")
      expect(page).to have_content("Form")
      expect(page).to have_content("Employee")
      expect(page).to have_content("Explanation")
    end

    scenario "Only included errors and cancellations appear" do

      # Errors that should appear

      RampElectionIntake.create!(
        veteran_file_number: "1110",
        completed_at: 0.hours.ago,
        completion_status: :error,
        error_code: :veteran_not_valid,
        user: current_user
      )

      RampElectionIntake.create!(
        veteran_file_number: "1111",
        completed_at: 1.hours.ago,
        completion_status: :error,
        error_code: :veteran_not_accessible,
        user: current_user
      )

      # Cancellations

      RampElectionIntake.create!(
        veteran_file_number: "1112",
        completed_at: 2.hours.ago,
        completion_status: :canceled,
        cancel_reason: :duplicate_ep,
        user: current_user
      )

      RampElectionIntake.create!(
        veteran_file_number: "1113",
        completed_at: 3.hours.ago,
        completion_status: :canceled,
        cancel_reason: :system_error,
        user: current_user
      )

      RampElectionIntake.create!(
        veteran_file_number: "1114",
        completed_at: 4.hours.ago,
        completion_status: :canceled,
        cancel_reason: :missing_signature,
        user: current_user
      )

      RampElectionIntake.create!(
        veteran_file_number: "1114",
        completed_at: 4.hours.ago,
        completion_status: :canceled,
        cancel_reason: :veteran_clarification,
        user: current_user
      )

      RampElectionIntake.create!(
        veteran_file_number: "1115",
        completed_at: 5.hours.ago,
        completion_status: :canceled,
        cancel_reason: :other,
        cancel_other: 'I am canceled just because',
        user: current_user
      )

      # Errors that should not appear, just checking a couple

      RampElectionIntake.create!(
        veteran_file_number: "2110",
        completed_at: 20.hours.ago,
        completion_status: :error,
        error_code: :veteran_not_found,
        user: current_user
      )

      RampElectionIntake.create!(
        veteran_file_number: "2110",
        completed_at: 20.hours.ago,
        completion_status: :error,
        error_code: :ramp_election_already_complete,
        user: current_user
      )

      RampElectionIntake.create!(
        veteran_file_number: "2110",
        completed_at: 20.hours.ago,
        completion_status: :error,
        error_code: :no_eligible_appeals,
        user: current_user
      )

      visit "/intake/manager"

      expect(find("#table-row-0")).to have_content("1110")
      expect(find("#table-row-0")).to have_content("8/07/2017")
      expect(find("#table-row-0")).to have_content(current_user.full_name)
      expect(find("#table-row-0")).to have_content("21-4138 RAMP Selection Form")
      expect(find("#table-row-0")).to have_content("Error: missing profile information")

      expect(find("#table-row-1")).to have_content("Error: sensitivity")
      expect(find("#table-row-2")).to have_content("Canceled: Duplicate EP created outside Caseflow")
      expect(find("#table-row-3")).to have_content("Canceled: System error")
      expect(find("#table-row-4")).to have_content("Canceled: Missing signature")
      expect(find("#table-row-5")).to have_content("Canceled: Need clarification from Veteran")
      expect(find("#table-row-6")).to have_content("Canceled: I am canceled just because")

      expect(page).not_to have_selector("#table-row-7")
    end
  end

  # To do
    # Create fake data for:
    # Each cancellation reason
    # Each included error and some excluded errors
    # successful ramp elections and ramp refilings (that succeeded on the first time)
    # successful ramp elections and refilings that previously were canceled
    # successful ramp elections and refilings that previously had errors
    #
    # Errors
    # Included
    # veteran_not_accessible
    # veteran_not_valid (missing information)
    #
    # Included Election only
    # no_eligible_appeals
    # no_active_fully_compensation_appeals
    #
    # Excluded
    # invalid_file_number
    # veteran_not_found
    # did_not_receive_ramp_election
    # ramp_election_already_complete
    # no_active_appeals
    # no_active_compensation_appeals
    # no_complete_ramp_election
    # ramp_election_is_active
    # ramp_election_no_issues
    # duplicate_intake_in_progress
    # ramp_refiling_already_processed
    # default
    #
    # Cancellation reasons
    # duplicate_ep
    # system_error
    # missing_signature
    # veteran_clarification
    # other


  scenario "Unauthorized user access" do
    # Authenticated access without System Admin role
    User.authenticate!(roles: ["Mail Intake"])
    visit "/intake/manager"
    expect(page).to have_content("You aren't authorized")
  end
end
