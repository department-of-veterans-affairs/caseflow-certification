require "rails_helper"

RSpec.feature "Appeal Intake" do
  before do
    FeatureToggle.enable!(:intake)
    # Test that this works when only enabled on the current user
    FeatureToggle.enable!(:intakeAma, users: [current_user.css_id])
    FeatureToggle.enable!(:intake_legacy_opt_in)

    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2018, 5, 20))
  end

  after do
    FeatureToggle.disable!(:intakeAma)
    FeatureToggle.disable!(:intake_legacy_opt_in)
  end

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

  let!(:veteran) do
    Generators::Veteran.build(
      file_number: "22334455",
      first_name: "Ed",
      last_name: "Merica",
      participant_id: "55443322"
    )
  end

  let(:veteran_no_ratings) do
    Generators::Veteran.build(file_number: "55555555",
                              first_name: "Nora",
                              last_name: "Attings",
                              participant_id: "44444444")
  end

  let(:receipt_date) { Date.new(2018, 4, 20) }

  let(:untimely_days) { 372.days }

  let(:profile_date) { (receipt_date - untimely_days + 4.days).to_time(:local) }

  let!(:rating) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date - untimely_days + 1.day,
      profile_date: profile_date,
      issues: [
        { reference_id: "abc123", decision_text: "Left knee granted" },
        { reference_id: "def456", decision_text: "PTSD denied" }
      ]
    )
  end

  let!(:untimely_rating) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date - untimely_days,
      profile_date: receipt_date - untimely_days + 3.days,
      issues: [
        { reference_id: "old123", decision_text: "Untimely rating issue 1" },
        { reference_id: "old456", decision_text: "Untimely rating issue 2" }
      ]
    )
  end

  let(:search_bar_title) { "Enter the Veteran's ID" }
  let(:search_page_title) { "Search for Veteran ID" }

  it "Creates an appeal" do
    # Testing no relationships in Appeal and Veteran is claimant, tests two relationships in HRL and one in SC
    allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return(nil)

    visit "/intake"
    safe_click ".Select"

    fill_in "Which form are you processing?", with: Constants.INTAKE_FORM_NAMES.appeal
    find("#form-select").send_keys :enter

    safe_click ".cf-submit.usa-button"

    expect(page).to have_content(search_page_title)

    fill_in search_bar_title, with: "22334455"

    click_on "Search"

    expect(page).to have_current_path("/intake/review_request")

    fill_in "What is the Receipt Date of this form?", with: "05/25/2018"
    safe_click "#button-submit-review"

    expect(page).to have_content("Receipt date cannot be in the future.")
    expect(page).to have_content("Please select an option.")

    fill_in "What is the Receipt Date of this form?", with: "04/20/2018"

    within_fieldset("Which review option did the Veteran request?") do
      find("label", text: "Evidence Submission", match: :prefer_exact).click
    end

    expect(page).to_not have_content("Please select the claimant listed on the form.")
    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "Yes", match: :prefer_exact).click
    end

    expect(page).to have_content("Please select the claimant listed on the form.")
    expect(page).to_not have_content("Bob Vance, Spouse")
    expect(page).to_not have_content("Cathy Smith, Child")

    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    within_fieldset("Did they agree to withdraw their issues from the legacy system?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    safe_click "#button-submit-review"

    expect(page).to have_current_path("/intake/finish")

    visit "/intake/review_request"

    expect(find_field("Evidence Submission", visible: false)).to be_checked
    expect(find("#different-claimant-option_false", visible: false)).to be_checked
    expect(find("#legacy-opt-in_false", visible: false)).to be_checked

    safe_click "#button-submit-review"

    appeal = Appeal.find_by(veteran_file_number: "22334455")
    intake = Intake.find_by(veteran_file_number: "22334455")

    expect(appeal).to_not be_nil
    expect(appeal.receipt_date).to eq(receipt_date)
    expect(appeal.docket_type).to eq("evidence_submission")
    expect(appeal.legacy_opt_in_approved).to eq(false)

    expect(page).to have_content("Identify issues on")

    expect(appeal.claimant_participant_id).to eq(
      intake.veteran.participant_id
    )

    expect(appeal.payee_code).to eq("00")
    expect(page).to have_content("Decision date: 04/17/2017")
    expect(page).to have_content("Left knee granted")
    expect(page).to have_content("Untimely rating issue 1")

    find("label", text: "PTSD denied").click

    safe_click "#button-add-issue"

    safe_click ".Select"
    expect(page).to have_content("1 issue")

    fill_in "Issue category", with: "Active Duty Adjustments"
    find("#issue-category").send_keys :enter

    expect(page).to have_content("1 issue")

    fill_in "Issue description", with: "Description for Active Duty Adjustments"

    expect(page).to have_content("1 issue")

    fill_in "Decision date", with: "04/19/2018"

    expect(page).to have_content("2 issues")

    safe_click "#button-finish-intake"

    expect(page).to have_content("Request for #{Constants.INTAKE_FORM_NAMES.appeal} has been processed.")
    expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES_SHORT.appeal} created:")
    expect(page).to have_content("Issue: Description for Active Duty Adjustments")

    intake.reload
    expect(intake.completed_at).to eq(Time.zone.now)

    expect(intake).to be_success

    appeal.reload
    expect(appeal.request_issues.count).to eq 2
    expect(appeal.request_issues.first).to have_attributes(
      rating_issue_reference_id: "def456",
      rating_issue_profile_date: profile_date,
      description: "PTSD denied",
      decision_date: nil
    )

    expect(appeal.request_issues.last).to have_attributes(
      rating_issue_reference_id: nil,
      rating_issue_profile_date: nil,
      issue_category: "Active Duty Adjustments",
      description: "Description for Active Duty Adjustments",
      decision_date: 1.month.ago.to_date
    )
  end

  it "Shows a review error when something goes wrong" do
    intake = AppealIntake.new(veteran_file_number: "22334455", user: current_user)
    intake.start!

    visit "/intake"

    fill_in "What is the Receipt Date of this form?", with: "04/20/2018"

    within_fieldset("Which review option did the Veteran request?") do
      find("label", text: "Evidence Submission", match: :prefer_exact).click
    end

    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    within_fieldset("Did they agree to withdraw their issues from the legacy system?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    ## Validate error message when complete intake fails
    expect_any_instance_of(AppealIntake).to receive(:review!).and_raise("A random error. Oh no!")

    safe_click "#button-submit-review"

    expect(page).to have_content("Something went wrong")
    expect(page).to have_current_path("/intake/review_request")
  end

  def start_appeal(test_veteran)
    appeal = Appeal.create!(
      veteran_file_number: test_veteran.file_number,
      receipt_date: 2.days.ago,
      docket_type: "evidence_submission",
      legacy_opt_in_approved: false
    )

    intake = AppealIntake.create!(
      veteran_file_number: test_veteran.file_number,
      user: current_user,
      started_at: 5.minutes.ago,
      detail: appeal
    )

    Claimant.create!(
      review_request: appeal,
      participant_id: test_veteran.participant_id
    )

    appeal.start_review!

    [appeal, intake]
  end

  it "Allows a Veteran without ratings to create an intake" do
    start_appeal(veteran_no_ratings)

    visit "/intake"

    safe_click "#button-submit-review"

    expect(page).to have_content("This Veteran has no rated, disability issues")

    safe_click "#button-add-issue"

    safe_click ".Select"

    fill_in "Issue category", with: "Active Duty Adjustments"
    find("#issue-category").send_keys :enter
    fill_in "Issue description", with: "Description for Active Duty Adjustments"
    fill_in "Decision date", with: "04/19/2018"

    expect(page).to have_content("1 issue")

    safe_click "#button-finish-intake"

    expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.appeal} has been processed.")
  end

  def check_row(label, text)
    row = find("tr", text: label)
    expect(row).to have_text(text)
  end

  scenario "For new Add / Remove Issues page" do
    duplicate_reference_id = "xyz789"
    old_reference_id = "old123"
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date - 40.days,
      profile_date: receipt_date - 50.days,
      issues: [
        { reference_id: "xyz123", decision_text: "Left knee granted" },
        { reference_id: "xyz456", decision_text: "PTSD denied" },
        { reference_id: duplicate_reference_id, decision_text: "Old injury in review" }
      ]
    )
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date - 400.days,
      profile_date: receipt_date - 450.days,
      issues: [
        { reference_id: old_reference_id, decision_text: "Really old injury" }
      ]
    )
    epe = create(:end_product_establishment, :active)
    request_issue_in_progress = create(
      :request_issue,
      end_product_establishment: epe,
      rating_issue_reference_id: duplicate_reference_id,
      description: "Old injury"
    )

    appeal, = start_appeal(veteran)
    visit "/intake/add_issues"

    expect(page).to have_content("Add / Remove Issues")
    check_row("Form", Constants.INTAKE_FORM_NAMES.appeal)
    check_row("Review option", "Evidence Submission")
    check_row("Claimant", "Ed Merica")

    # clicking the add issues button should bring up the modal
    safe_click "#button-add-issue"
    expect(page).to have_content("Add issue 1")
    expect(page).to have_content("Does issue 1 match any of these issues")
    expect(page).to have_content("Left knee granted")
    expect(page).to have_content("PTSD denied")

    # test canceling adding an issue by closing the modal
    safe_click ".close-modal"
    expect(page).to_not have_content("Left knee granted")

    # adding an issue should show the issue
    safe_click "#button-add-issue"
    find_all("label", text: "Left knee granted").first.click
    safe_click ".add-issue"

    expect(page).to have_content("1. Left knee granted")
    expect(page).to_not have_content("Notes:")

    # removing the issue should hide the issue
    safe_click ".remove-issue"

    expect(page).to_not have_content("Left knee granted")

    # re-add to proceed
    safe_click "#button-add-issue"
    find_all("label", text: "Left knee granted").first.click
    fill_in "Notes", with: "I am an issue note"
    safe_click ".add-issue"

    expect(page).to have_content("1. Left knee granted")
    expect(page).to have_content("I am an issue note")

    # clicking add issue again should show a disabled radio button for that same rating
    safe_click "#button-add-issue"

    expect(page).to have_content("Add issue 2")
    expect(page).to have_content("Does issue 2 match any of these issues")
    expect(page).to have_content("Left knee granted (already selected for issue 1)")
    expect(page).to have_css("input[disabled][id='rating-radio_xyz123']", visible: false)

    # Add non-rated issue
    safe_click ".no-matching-issues"
    expect(page).to have_content("Does issue 2 match any of these issue categories?")
    expect(page).to have_button("Add this issue", disabled: true)
    fill_in "Issue category", with: "Active Duty Adjustments"
    find("#issue-category").send_keys :enter
    fill_in "Issue description", with: "Description for Active Duty Adjustments"
    fill_in "Decision date", with: "04/19/2018"
    expect(page).to have_button("Add this issue", disabled: false)
    safe_click ".add-issue"
    expect(page).to have_content("2 issues")
    # this nonrated issue is timely
    expect(page).to_not have_content(
      "Description for Active Duty Adjustments #{Constants.INELIGIBLE_REQUEST_ISSUES.untimely}"
    )

    # add unidentified issue
    safe_click "#button-add-issue"
    safe_click ".no-matching-issues"
    safe_click ".no-matching-issues"
    expect(page).to have_content("Describe the issue to mark it as needing further review.")
    fill_in "Transcribe the issue as it's written on the form", with: "This is an unidentified issue"
    safe_click ".add-issue"
    expect(page).to have_content("3 issues")
    expect(page).to have_content("This is an unidentified issue")

    # add ineligible issue
    safe_click "#button-add-issue"
    find_all("label", text: "Old injury in review").first.click
    safe_click ".add-issue"
    expect(page).to have_content("4 issues")
    expect(page).to have_content("4. Old injury in review is ineligible because it's already under review as a Appeal")

    # add untimely rated issue
    safe_click "#button-add-issue"
    find_all("label", text: "Really old injury").first.click
    safe_click ".add-issue"
    expect(page).to have_content("The issue requested isn't usually eligible because its decision date is older")
    find_all("label", text: "Yes").first.click
    fill_in "Notes", with: "I am an exemption note"
    safe_click ".add-issue"
    expect(page).to have_content("5 issues")
    expect(page).to have_content("I am an exemption note")
    expect(page).to_not have_content("5. Really old injury #{Constants.INELIGIBLE_REQUEST_ISSUES.untimely}")

    # remove and re-add with different answer to exemption
    page.all(".remove-issue").last.click
    safe_click "#button-add-issue"
    find_all("label", text: "Really old injury").first.click
    safe_click ".add-issue"
    expect(page).to have_content("The issue requested isn't usually eligible because its decision date is older")
    find_all("label", text: "No").first.click
    fill_in "Notes", with: "I am an exemption note"
    safe_click ".add-issue"
    expect(page).to have_content("5 issues")
    expect(page).to have_content("I am an exemption note")
    expect(page).to have_content("5. Really old injury #{Constants.INELIGIBLE_REQUEST_ISSUES.untimely}")

    # add untimely nonrated issue
    safe_click "#button-add-issue"
    safe_click ".no-matching-issues"
    expect(page).to have_button("Add this issue", disabled: true)
    fill_in "Issue category", with: "Active Duty Adjustments"
    find("#issue-category").send_keys :enter
    fill_in "Issue description", with: "Another Description for Active Duty Adjustments"
    fill_in "Decision date", with: "04/19/2016"
    expect(page).to have_button("Add this issue", disabled: false)
    safe_click ".add-issue"
    expect(page).to have_content("6 issues")
    expect(page).to have_content(
      "Another Description for Active Duty Adjustments #{Constants.INELIGIBLE_REQUEST_ISSUES.untimely}"
    )

    safe_click "#button-finish-intake"

    expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.appeal} has been processed.")
    expect(page).to have_content("This is an unidentified issue")

    expect(Appeal.find_by(
             id: appeal.id,
             veteran_file_number: veteran.file_number,
             established_at: Time.zone.now
    )).to_not be_nil

    expect(RequestIssue.find_by(
             review_request: appeal,
             rating_issue_reference_id: "xyz123",
             description: "Left knee granted",
             notes: "I am an issue note"
    )).to_not be_nil

    expect(RequestIssue.find_by(
             review_request: appeal,
             description: "Really old injury",
             untimely_exemption: false,
             untimely_exemption_notes: "I am an exemption note"
    )).to_not be_nil

    expect(RequestIssue.find_by(
             review_request_type: "Appeal",
             review_request_id: appeal.id,
             issue_category: "Active Duty Adjustments",
             description: "Description for Active Duty Adjustments",
             decision_date: 1.month.ago
    )).to_not be_nil

    expect(RequestIssue.find_by(
             review_request: appeal,
             description: "This is an unidentified issue",
             is_unidentified: true
    )).to_not be_nil

    duplicate_request_issues = RequestIssue.where(rating_issue_reference_id: duplicate_reference_id)
    ineligible_issue = duplicate_request_issues.select(&:duplicate_of_issue_in_active_review?).first

    expect(duplicate_request_issues.count).to eq(2)
    expect(duplicate_request_issues).to include(request_issue_in_progress)
    expect(ineligible_issue).to_not eq(request_issue_in_progress)

    expect(RequestIssue.find_by(rating_issue_reference_id: old_reference_id).eligible?).to eq(false)
  end

  it "Shows a review error when something goes wrong" do
    start_appeal(veteran)
    visit "/intake/add_issues"

    safe_click "#button-add-issue"
    find_all("label", text: "Left knee granted").first.click
    fill_in "Notes", with: "I am an issue note"
    safe_click ".add-issue"

    ## Validate error message when complete intake fails
    expect_any_instance_of(AppealIntake).to receive(:complete!).and_raise("A random error. Oh no!")

    safe_click "#button-finish-intake"

    expect(page).to have_content("Something went wrong")
    expect(page).to have_current_path("/intake/add_issues")
  end

  scenario "canceling an appeal intake" do
    _, intake = start_appeal(veteran)
    visit "/intake/add_issues"

    expect(page).to have_content("Add / Remove Issues")
    safe_click "#cancel-intake"
    expect(find("#modal_id-title")).to have_content("Cancel Intake?")
    safe_click ".close-modal"
    expect(page).to_not have_css("#modal_id-title")
    safe_click "#cancel-intake"

    safe_click ".confirm-cancel"
    expect(page).to have_content("Make sure you’ve selected an option below.")
    within_fieldset("Please select the reason you are canceling this intake.") do
      find("label", text: "Other").click
    end
    safe_click ".confirm-cancel"
    expect(page).to have_content("Make sure you’ve filled out the comment box below.")
    fill_in "Tell us more about your situation.", with: "blue!"
    safe_click ".confirm-cancel"

    expect(page).to have_content("Welcome to Caseflow Intake!")
    expect(page).to_not have_css(".cf-modal-title")

    intake.reload
    expect(intake.completed_at).to eq(Time.zone.now)
    expect(intake.cancel_reason).to eq("other")
    expect(intake).to be_canceled
  end
end
