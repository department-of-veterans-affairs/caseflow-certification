require "support/intake_helpers"

feature "Edit issues" do
  include IntakeHelpers

  before do
    FeatureToggle.enable!(:intake)
    FeatureToggle.enable!(:intakeAma)
    FeatureToggle.enable!(:intake_legacy_opt_in)

    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2018, 5, 26))

    # skip the sync call since all edit requests require resyncing
    # currently, we're not mocking out vbms and bgs
    allow_any_instance_of(EndProductEstablishment).to receive(:sync!).and_return(nil)
  end

  after do
    FeatureToggle.disable!(:intakeAma)
    FeatureToggle.disable!(:intake_legacy_opt_in)
  end

  let(:veteran) do
    create(:veteran,
           first_name: "Ed",
           last_name: "Merica")
  end

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

  let(:receipt_date) { Time.zone.today - 20 }
  let(:profile_date) { "2017-11-02T07:00:00.000Z" }

  let!(:rating) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date,
      profile_date: profile_date,
      issues: [
        { reference_id: "abc123", decision_text: "Left knee granted", contention_reference_id: 55 },
        { reference_id: "def456", decision_text: "PTSD denied" },
        { reference_id: "abcdef", decision_text: "Back pain" }
      ]
    )
  end

  let!(:rating_before_ama) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: DecisionReview.ama_activation_date - 5.days,
      profile_date: DecisionReview.ama_activation_date - 10.days,
      issues: [
        { reference_id: "before_ama_ref_id", decision_text: "Non-RAMP Issue before AMA Activation" }
      ]
    )
  end

  let!(:rating_before_ama_from_ramp) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: DecisionReview.ama_activation_date - 5.days,
      profile_date: DecisionReview.ama_activation_date - 11.days,
      issues: [
        { decision_text: "Issue before AMA Activation from RAMP",
          reference_id: "ramp_ref_id" }
      ],
      associated_claims: { bnft_clm_tc: "683SCRRRAMP", clm_id: "ramp_claim_id" }
    )
  end

  let!(:ratings_with_legacy_issues) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date - 4.days,
      profile_date: receipt_date - 4.days,
      issues: [
        { reference_id: "has_legacy_issue", decision_text: "Issue with legacy issue not withdrawn" },
        { reference_id: "has_ineligible_legacy_appeal", decision_text: "Issue connected to ineligible legacy appeal" }
      ]
    )
  end

  def check_row(label, text)
    row = find("tr", text: label)
    expect(row).to have_text(text)
  end

  context "appeals" do
    let(:legacy_opt_in_approved) { false }
    let!(:appeal) do
      create(:appeal,
             veteran_file_number: veteran.file_number,
             receipt_date: receipt_date,
             docket_type: "evidence_submission",
             veteran_is_not_claimant: false,
             legacy_opt_in_approved: legacy_opt_in_approved).tap(&:create_tasks_on_intake_success!)
    end

    let(:nonrating_request_issue_attributes) do
      {
        review_request: appeal,
        issue_category: "Military Retired Pay",
        description: "nonrating description",
        contention_reference_id: "1234",
        decision_date: 1.month.ago
      }
    end

    let!(:nonrating_request_issue) { create(:request_issue, nonrating_request_issue_attributes) }

    let(:rating_request_issue_attributes) do
      {
        review_request: appeal,
        contested_rating_issue_reference_id: "def456",
        contested_rating_issue_profile_date: profile_date,
        description: "PTSD denied",
        contention_reference_id: "4567"
      }
    end

    let!(:rating_request_issue) { create(:request_issue, rating_request_issue_attributes) }

    scenario "allows adding/removing issues" do
      visit "appeals/#{appeal.uuid}/edit/"

      expect(page).to have_content(nonrating_request_issue.description)

      # remove an issue
      nonrating_intake_num = find_intake_issue_number_by_text(nonrating_request_issue.issue_category)
      click_remove_intake_issue(nonrating_intake_num)
      click_remove_issue_confirmation
      expect(page).not_to have_content(nonrating_request_issue.description)

      # add a different issue
      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")

      # save
      expect(page).to have_content("Left knee granted")
      safe_click("#button-submit-update")

      # should redirect to queue
      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

      # going back to edit page should show those issues
      visit "appeals/#{appeal.uuid}/edit/"
      expect(page).to have_content("Left knee granted")
      expect(page).not_to have_content("nonrating description")

      # canceling should redirect to queue
      click_on "Cancel"
      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")
    end

    scenario "allows removing and re-adding same issue" do
      issue_description = rating_request_issue.description

      visit "appeals/#{appeal.uuid}/edit/"

      expect(page).to have_content(issue_description)
      expect(page).to have_button("Save", disabled: true)

      # remove
      issue_num = find_intake_issue_number_by_text(issue_description)
      click_remove_intake_issue(issue_num)
      click_remove_issue_confirmation
      expect(page).not_to have_content(issue_description)

      # re-add
      click_intake_add_issue
      add_intake_rating_issue(issue_description, "a new comment")
      expect(page).to have_content(issue_description)
      expect(page).to_not have_content(
        Constants.INELIGIBLE_REQUEST_ISSUES.duplicate_of_rating_issue_in_active_review.gsub("{review_title}", "Appeal")
      )

      # issue note was added
      expect(page).to have_button("Save", disabled: false)
    end

    context "with multiple request issues with same data fields" do
      let!(:duplicate_nonrating_request_issue) { create(:request_issue, nonrating_request_issue_attributes) }
      let!(:duplicate_rating_request_issue) { create(:request_issue, rating_request_issue_attributes) }

      scenario "saves by id" do
        visit "appeals/#{appeal.uuid}/edit/"
        expect(page).to have_content(duplicate_nonrating_request_issue.description, count: 2)
        expect(page).to have_content(duplicate_rating_request_issue.description, count: 2)

        # add another new issue
        click_intake_add_issue
        click_intake_no_matching_issues
        add_intake_nonrating_issue(
          category: "Active Duty Adjustments",
          description: "A description!",
          date: "04/26/2018"
        )

        safe_click("#button-submit-update")
        safe_click ".confirm"
        expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

        request_issue_update = RequestIssuesUpdate.where(review: appeal).last
        non_modified_ids = [duplicate_nonrating_request_issue.id, duplicate_rating_request_issue.id,
                            nonrating_request_issue.id, rating_request_issue.id]

        # duplicate issues should be neither added nor removed
        expect(request_issue_update.created_issues.map(&:id)).to_not include(non_modified_ids)
        expect(request_issue_update.removed_issues.map(&:id)).to_not include(non_modified_ids)
      end
    end

    context "with legacy appeals" do
      before do
        setup_legacy_opt_in_appeals(veteran.file_number)
      end

      context "with legacy_opt_in_approved" do
        let(:legacy_opt_in_approved) { true }
        scenario "adding issues" do
          visit "appeals/#{appeal.uuid}/edit/"

          click_intake_add_issue
          expect(page).to have_content("Next")
          add_intake_rating_issue("Left knee granted")

          # expect legacy opt in modal
          expect(page).to have_content("Does issue 3 match any of these VACOLS issues?")

          add_intake_rating_issue("intervertebral disc syndrome") # ineligible issue

          expect(page).to have_content(
            "Left knee granted #{Constants.INELIGIBLE_REQUEST_ISSUES.legacy_appeal_not_eligible}"
          )

          click_intake_add_issue
          add_intake_rating_issue("Back pain")
          add_intake_rating_issue("ankylosis of hip") # eligible issue

          safe_click("#button-submit-update")
          safe_click ".confirm"

          expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

          expect(RequestIssue.find_by(
                   description: "Left knee granted",
                   ineligible_reason: :legacy_appeal_not_eligible,
                   vacols_id: "vacols2",
                   vacols_sequence_id: "1"
                 )).to_not be_nil

          ri_with_optin = RequestIssue.find_by(
            description: "Back pain",
            ineligible_reason: nil,
            vacols_id: "vacols1",
            vacols_sequence_id: "1"
          )

          expect(ri_with_optin).to_not be_nil
          li_optin = ri_with_optin.legacy_issue_optin
          expect(li_optin.optin_processed_at).to_not be_nil
          expect(VACOLS::CaseIssue.find_by(isskey: "vacols1", issseq: 1).issdc).to eq(
            LegacyIssueOptin::VACOLS_DISPOSITION_CODE
          )

          # Check rollback
          visit "appeals/#{appeal.uuid}/edit/"
          click_remove_intake_issue_by_text("Back pain")
          click_remove_issue_confirmation
          safe_click("#button-submit-update")
          safe_click ".confirm"

          expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")
          expect(li_optin.reload.rollback_processed_at).to_not be_nil
          expect(VACOLS::CaseIssue.find_by(isskey: "vacols1", issseq: 1).issdc).to eq(
            li_optin.original_disposition_code
          )
        end
      end

      context "with legacy opt in not approved" do
        let(:legacy_opt_in_approved) { false }
        scenario "adding issues" do
          visit "appeals/#{appeal.uuid}/edit/"
          click_intake_add_issue
          add_intake_rating_issue("Left knee granted")

          expect(page).to have_content("Does issue 3 match any of these VACOLS issues?")
          # do not show inactive appeals when legacy opt in is false
          expect(page).to_not have_content("impairment of hip")
          expect(page).to_not have_content("typhoid arthritis")

          add_intake_rating_issue("ankylosis of hip")

          expect(page).to have_content(
            "Left knee granted #{Constants.INELIGIBLE_REQUEST_ISSUES.legacy_issue_not_withdrawn}"
          )

          safe_click("#button-submit-update")
          safe_click ".confirm"

          expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

          expect(RequestIssue.find_by(
                   description: "Left knee granted",
                   ineligible_reason: :legacy_issue_not_withdrawn,
                   vacols_id: "vacols1",
                   vacols_sequence_id: "1"
                 )).to_not be_nil
        end
      end

      scenario "adding issue with legacy opt in disabled" do
        allow(FeatureToggle).to receive(:enabled?).and_call_original
        allow(FeatureToggle).to receive(:enabled?).with(:intake_legacy_opt_in, user: current_user).and_return(false)

        visit "appeals/#{appeal.uuid}/edit/"

        click_intake_add_issue
        expect(page).to have_content("Add this issue")
        add_intake_rating_issue("Left knee granted")
        expect(page).to have_content("Left knee granted")
      end
    end
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def verify_decision_issues_can_be_added_and_removed(page_url,
                                                      original_request_issue,
                                                      review_request,
                                                      contested_decision_issues)
    visit page_url
    expect(page).to have_content("currently contesting decision issue")
    expect(page).to have_content("PTSD denied")

    # check that we cannot add the same issue again
    click_intake_add_issue
    expect(page).to have_css("input[disabled]", visible: false)
    expect(page).to have_content("PTSD denied (already selected for")

    nonrating_decision_issue_description = "nonrating decision issue dispositon: " \
                                           "Active Duty Adjustments - Test nonrating decision issue"
    rating_decision_issue_description = "a rating decision issue"
    # check that nonrating and rating decision issues show up

    expect(page).to have_content(nonrating_decision_issue_description)
    expect(page).to have_content(rating_decision_issue_description)
    safe_click ".close-modal"

    # remove original decision issue
    click_remove_intake_issue_by_text("currently contesting decision issue")
    click_remove_issue_confirmation

    # add new decision issue

    click_intake_add_issue
    add_intake_rating_issue(rating_decision_issue_description)
    expect(page).to have_content(rating_decision_issue_description)

    click_intake_add_issue

    add_intake_rating_issue(nonrating_decision_issue_description)
    expect(page).to have_content(nonrating_decision_issue_description)
    expect(page).to have_content(
      Constants.INELIGIBLE_REQUEST_ISSUES
        .duplicate_of_rating_issue_in_active_review.gsub("{review_title}", "Higher-Level Review")
    )

    safe_click("#button-submit-update")
    safe_click ".confirm"
    expect(page).to have_content("Edit Confirmed")

    visit page_url
    expect(page).to have_content(nonrating_decision_issue_description)
    expect(page).to have_content(rating_decision_issue_description)
    expect(page).to have_content("PTSD denied")

    # check that decision_request_issue is closed
    updated_request_issue = RequestIssue.find_by(id: original_request_issue.id)
    expect(updated_request_issue.review_request).to be_nil

    # check that new request issue is created contesting the decision issue
    expect(RequestIssue.find_by(review_request: review_request,
                                contested_decision_issue_id: contested_decision_issues.first.id,
                                description: contested_decision_issues.first.formatted_description)).to_not be_nil

    expect(RequestIssue.find_by(review_request: review_request,
                                contested_decision_issue_id: contested_decision_issues.second.id,
                                ineligible_reason: :duplicate_of_rating_issue_in_active_review,
                                description: contested_decision_issues.second.formatted_description)).to_not be_nil
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def verify_request_issue_contending_decision_issue_not_readded(
      page_url,
      decision_review,
      contested_decision_issues
    )
    # verify that not modifying a request issue contenting a decision issue
    # does not result in readding

    visit page_url
    expect(page).to have_content(contested_decision_issues.first.description)
    expect(page).to have_content(contested_decision_issues.second.description)
    expect(page).to have_content("PTSD denied")

    click_remove_intake_issue_by_text("PTSD denied")
    click_remove_issue_confirmation

    click_intake_add_issue
    add_intake_rating_issue("Issue with legacy issue not withdrawn")

    safe_click("#button-submit-update")
    expect(page).to have_content("Edit Confirmed")

    first_not_modified_request_issue = RequestIssue.find_by(
      review_request: decision_review,
      contested_decision_issue_id: contested_decision_issues.first.id
    )

    second_not_modified_request_issue = RequestIssue.find_by(
      review_request: decision_review,
      contested_decision_issue_id: contested_decision_issues.second.id
    )

    expect(first_not_modified_request_issue).to_not be_nil
    expect(second_not_modified_request_issue).to_not be_nil

    non_modified_ids = [first_not_modified_request_issue.id, second_not_modified_request_issue.id]
    request_issue_update = RequestIssuesUpdate.find_by(review: decision_review)

    # existing issues should not be added or removed
    expect(request_issue_update.created_issues.map(&:id)).to_not include(non_modified_ids)
    expect(request_issue_update.removed_issues.map(&:id)).to_not include(non_modified_ids)
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  context "Higher-Level Reviews" do
    let!(:higher_level_review) do
      HigherLevelReview.create!(
        veteran_file_number: veteran.file_number,
        receipt_date: receipt_date,
        informal_conference: false,
        same_office: false,
        benefit_type: "compensation",
        veteran_is_not_claimant: true
      )
    end

    let!(:another_higher_level_review) do
      HigherLevelReview.create!(
        veteran_file_number: veteran.file_number,
        receipt_date: receipt_date,
        informal_conference: false,
        same_office: false,
        benefit_type: "compensation"
      )
    end

    # create associated intake
    let!(:intake) do
      Intake.create!(
        user_id: current_user.id,
        detail: higher_level_review,
        veteran_file_number: veteran.file_number,
        started_at: Time.zone.now,
        completed_at: Time.zone.now,
        completion_status: "success",
        type: "HigherLevelReviewIntake"
      )
    end

    before do
      higher_level_review.create_claimants!(participant_id: "5382910292", payee_code: "10")

      allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
      allow(Fakes::VBMSService).to receive(:remove_contention!).and_call_original

      allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return(
        first_name: "BOB",
        last_name: "VANCE",
        ptcpnt_id: "5382910292",
        relationship_type: "Spouse"
      )
    end

    context "when there are ineligible issues" do
      ineligible = Constants.INELIGIBLE_REQUEST_ISSUES

      let!(:eligible_request_issue) do
        RequestIssue.create!(
          review_request: higher_level_review,
          benefit_type: "compensation",
          issue_category: "Military Retired Pay",
          description: "eligible nonrating description",
          contention_reference_id: "1234",
          ineligible_reason: nil,
          decision_date: Date.new(2018, 5, 1)
        )
      end

      let!(:untimely_request_issue) do
        RequestIssue.create!(
          review_request: higher_level_review,
          issue_category: "Active Duty Adjustments",
          description: "untimely nonrating description",
          contention_reference_id: "12345",
          ineligible_reason: :untimely
        )
      end

      let!(:ri_in_review) do
        RequestIssue.create!(
          contested_rating_issue_reference_id: "def456",
          contested_rating_issue_profile_date: rating.profile_date,
          review_request: another_higher_level_review,
          description: "PTSD denied",
          contention_reference_id: "123",
          ineligible_reason: nil,
          removed_at: nil
        )
      end

      let!(:ri_with_active_previous_review) do
        RequestIssue.create!(
          contested_rating_issue_reference_id: "def456",
          contested_rating_issue_profile_date: rating.profile_date,
          review_request: higher_level_review,
          description: "PTSD denied",
          contention_reference_id: "111",
          ineligible_reason: :duplicate_of_rating_issue_in_active_review,
          ineligible_due_to: ri_in_review
        )
      end

      let!(:ri_previous_hlr) do
        RequestIssue.create!(
          contested_rating_issue_reference_id: "abc123",
          contested_rating_issue_profile_date: rating.profile_date,
          review_request: another_higher_level_review,
          description: "Left knee granted",
          contention_reference_id: 55
        )
      end

      let!(:ri_with_previous_hlr) do
        RequestIssue.create!(
          contested_rating_issue_reference_id: "abc123",
          contested_rating_issue_profile_date: rating.profile_date,
          review_request: higher_level_review,
          description: "Left knee granted",
          ineligible_reason: :higher_level_review_to_higher_level_review,
          ineligible_due_to: ri_previous_hlr
        )
      end

      let!(:ri_before_ama) do
        RequestIssue.create!(
          contested_rating_issue_reference_id: "before_ama_ref_id",
          contested_rating_issue_profile_date: rating_before_ama.profile_date,
          review_request: higher_level_review,
          description: "Non-RAMP Issue before AMA Activation",
          contention_reference_id: "12345",
          ineligible_reason: :before_ama
        )
      end

      let!(:eligible_ri_before_ama) do
        RequestIssue.create!(
          contested_rating_issue_reference_id: "ramp_ref_id",
          contested_rating_issue_profile_date: rating_before_ama_from_ramp.profile_date,
          review_request: higher_level_review,
          description: "Issue before AMA Activation from RAMP",
          contention_reference_id: "123456",
          ramp_claim_id: "ramp_claim_id"
        )
      end

      let!(:ri_legacy_issue_not_withdrawn) do
        RequestIssue.create!(
          contested_rating_issue_reference_id: "has_legacy_issue",
          contested_rating_issue_profile_date: rating_before_ama.profile_date,
          review_request: higher_level_review,
          description: "Issue with legacy issue not withdrawn",
          vacols_id: "vacols1",
          vacols_sequence_id: "1",
          contention_reference_id: "1234567",
          ineligible_reason: :legacy_issue_not_withdrawn
        )
      end

      let!(:ri_legacy_issue_ineligible) do
        RequestIssue.create!(
          contested_rating_issue_reference_id: "has_ineligible_legacy_appeal",
          contested_rating_issue_profile_date: rating_before_ama.profile_date,
          review_request: higher_level_review,
          description: "Issue connected to ineligible legacy appeal",
          contention_reference_id: "12345678",
          vacols_id: "vacols2",
          vacols_sequence_id: "2",
          ineligible_reason: :legacy_appeal_not_eligible
        )
      end

      let(:ep_claim_id) do
        EndProductEstablishment.find_by(
          source: higher_level_review,
          code: "030HLRNR"
        ).reference_id
      end

      before do
        setup_legacy_opt_in_appeals(veteran.file_number)
        another_higher_level_review.create_issues!([ri_in_review])
        higher_level_review.create_issues!([
                                             eligible_request_issue,
                                             untimely_request_issue,
                                             ri_with_active_previous_review,
                                             ri_with_previous_hlr,
                                             ri_before_ama,
                                             eligible_ri_before_ama,
                                             ri_legacy_issue_not_withdrawn,
                                             ri_legacy_issue_ineligible
                                           ])
        higher_level_review.establish!
      end

      it "shows the Higher-Level Review Edit page with ineligibility messages" do
        visit "higher_level_reviews/#{ep_claim_id}/edit"
        expect(page).to have_content(
          "#{ri_with_previous_hlr.contention_text} #{ineligible.higher_level_review_to_higher_level_review}"
        )
        expect(page).to have_content(
          "#{ri_in_review.contention_text} is ineligible because it's already under review as a Higher-Level Review"
        )
        expect(page).to have_content(
          "#{untimely_request_issue.contention_text} #{ineligible.untimely}"
        )
        expect(page).to have_content("#{eligible_request_issue.contention_text} Decision date: 05/01/2018")
        expect(page).to have_content(
          "#{ri_before_ama.contention_text} #{ineligible.before_ama}"
        )
        expect(page).to have_content(
          "#{eligible_ri_before_ama.contention_text} Decision date:"
        )
        expect(page).to have_content(
          "#{ri_legacy_issue_not_withdrawn.contention_text} #{ineligible.legacy_issue_not_withdrawn}"
        )
        expect(page).to have_content(
          "#{ri_legacy_issue_ineligible.contention_text} #{ineligible.legacy_appeal_not_eligible}"
        )
      end

      it "re-applies eligibility check on remove/re-add of ineligible issue" do
        visit "higher_level_reviews/#{ep_claim_id}/edit"

        expect(page).to have_content("8 issues")

        # remove and re-add each ineligible issue. when re-added, it should always be issue 8.
        # excludes ineligible legacy opt in issue because it requires the HLR to have that option selected

        # 1
        ri_legacy_issue_not_withdrawn_num = find_intake_issue_number_by_text(
          ri_legacy_issue_not_withdrawn.contention_text
        )
        expect_ineligible_issue(ri_legacy_issue_not_withdrawn_num)
        click_remove_intake_issue(ri_legacy_issue_not_withdrawn_num)
        click_remove_issue_confirmation

        expect(page).to_not have_content(
          "#{ri_legacy_issue_not_withdrawn.contention_text} #{ineligible.legacy_issue_not_withdrawn}"
        )

        click_intake_add_issue
        add_intake_rating_issue(ri_legacy_issue_not_withdrawn.contention_text)
        add_intake_rating_issue("ankylosis of hip")

        expect_ineligible_issue(8)

        expect(page).to have_content(
          "#{ri_legacy_issue_not_withdrawn.contention_text} #{ineligible.legacy_issue_not_withdrawn}"
        )

        # 4
        ri_with_previous_hlr_issue_num = find_intake_issue_number_by_text(ri_with_previous_hlr.contention_text)
        expect_ineligible_issue(ri_with_previous_hlr_issue_num)
        click_remove_intake_issue(ri_with_previous_hlr_issue_num)
        click_remove_issue_confirmation

        expect(page).to_not have_content(
          "#{ri_with_previous_hlr.contention_text} #{ineligible.higher_level_review_to_higher_level_review}"
        )

        click_intake_add_issue
        add_intake_rating_issue(ri_with_previous_hlr.contention_text)
        add_intake_rating_issue("None of these match")

        expect_ineligible_issue(8)
        expect(page).to have_content(
          "#{ri_with_previous_hlr.contention_text} #{ineligible.higher_level_review_to_higher_level_review}"
        )

        # 5
        ri_in_review_issue_num = find_intake_issue_number_by_text(ri_in_review.contention_text)
        expect_ineligible_issue(ri_in_review_issue_num)
        click_remove_intake_issue(ri_in_review_issue_num)
        click_remove_issue_confirmation

        expect(page).to_not have_content(
          "#{ri_in_review.contention_text} is ineligible because it's already under review as a Higher-Level Review"
        )

        click_intake_add_issue
        add_intake_rating_issue(ri_in_review.contention_text)
        add_intake_rating_issue("None of these match")

        expect_ineligible_issue(8)
        expect(page).to have_content(
          "#{ri_in_review.contention_text} is ineligible because it's already under review as a Higher-Level Review"
        )

        # 6
        untimely_request_issue_num = find_intake_issue_number_by_text(untimely_request_issue.contention_text)
        expect_ineligible_issue(untimely_request_issue_num)
        click_remove_intake_issue(untimely_request_issue_num)
        click_remove_issue_confirmation

        expect(page).to_not have_content(
          "#{untimely_request_issue.contention_text} #{ineligible.untimely}"
        )

        click_intake_add_issue
        click_intake_no_matching_issues
        add_intake_nonrating_issue(
          category: "Active Duty Adjustments",
          description: untimely_request_issue.contention_text,
          date: "01/01/2016",
          legacy_issues: true
        )
        add_intake_rating_issue("None of these match")
        add_untimely_exemption_response("No", "I am a nonrating exemption note")

        expect_ineligible_issue(8)
        expect(page).to have_content(
          "#{untimely_request_issue.contention_text} #{ineligible.untimely}"
        )

        # 7
        ri_before_ama_num = find_intake_issue_number_by_text(ri_before_ama.contention_text)
        expect_ineligible_issue(ri_before_ama_num)
        click_remove_intake_issue(ri_before_ama_num)
        click_remove_issue_confirmation

        expect(page).to_not have_content(
          "#{ri_before_ama.contention_text} #{ineligible.before_ama}"
        )

        click_intake_add_issue
        add_intake_rating_issue(ri_before_ama.contention_text)
        add_intake_rating_issue("None of these match")

        expect_ineligible_issue(8)
        expect(page).to have_content(
          "#{ri_before_ama.contention_text} #{ineligible.before_ama}"
        )
      end
    end

    context "when there is a nonrating end product" do
      let!(:nonrating_request_issue) do
        RequestIssue.create!(
          review_request: higher_level_review,
          issue_category: "Military Retired Pay",
          description: "nonrating description",
          contention_reference_id: "1234",
          decision_date: 1.month.ago
        )
      end

      let(:nonrating_ep_claim_id) do
        EndProductEstablishment.find_by(
          source: higher_level_review,
          code: "030HLRNR"
        ).reference_id
      end

      before do
        higher_level_review.create_issues!([nonrating_request_issue])
        higher_level_review.establish!
      end

      it "shows the Higher-Level Review Edit page with a nonrating claim id" do
        visit "higher_level_reviews/#{nonrating_ep_claim_id}/edit"

        expect(page).to have_content("Military Retired Pay")

        click_intake_add_issue
        click_intake_no_matching_issues
        add_intake_nonrating_issue(
          category: "Active Duty Adjustments",
          description: "A description!",
          date: "04/26/2018"
        )

        click_intake_add_issue
        click_intake_no_matching_issues
        add_intake_nonrating_issue(
          category: "Drill Pay Adjustments",
          description: "A nonrating issue before AMA",
          date: "10/25/2017"
        )

        safe_click("#button-submit-update")

        expect(page).to have_content("The review originally had 1 issue but now has 3.")
        expect(page).to have_content(
          "A nonrating issue before AMA #{Constants.INELIGIBLE_REQUEST_ISSUES.before_ama}"
        )
        safe_click ".confirm"

        expect(page).to have_current_path(
          "/higher_level_reviews/#{nonrating_ep_claim_id}/edit/confirmation"
        )
        expect(page).to have_content("Edit Confirmed")
      end

      context "when veteran has active nonrating request issues" do
        let!(:active_nonrating_request_issue) do
          create(:request_issue,
                 :nonrating,
                 review_request: another_higher_level_review)
        end

        before do
          another_higher_level_review.create_issues!([active_nonrating_request_issue])
        end

        scenario "shows ineligibility message and saves conflicting request issue id" do
          visit "higher_level_reviews/#{nonrating_ep_claim_id}/edit"
          click_intake_add_issue
          click_intake_no_matching_issues

          fill_in "Issue category", with: active_nonrating_request_issue.issue_category
          find("#issue-category").send_keys :enter
          expect(page).to have_content("Does issue 2 match any of the issues actively being reviewed?")
          expect(page).to have_content("#{active_nonrating_request_issue.issue_category}: " \
                                       "#{active_nonrating_request_issue.description}")
          add_active_intake_nonrating_issue(active_nonrating_request_issue.issue_category)
          expect(page).to have_content("#{active_nonrating_request_issue.issue_category} -" \
                                       " #{active_nonrating_request_issue.description}" \
                                       " is ineligible because it's already under review as a Higher-Level Review")

          safe_click("#button-submit-update")
          safe_click ".confirm"
          expect(page).to have_content("Edit Confirmed")

          expect(RequestIssue.find_by(review_request: higher_level_review,
                                      issue_category: active_nonrating_request_issue.issue_category,
                                      ineligible_due_to: active_nonrating_request_issue.id,
                                      ineligible_reason: "duplicate_of_nonrating_issue_in_active_review",
                                      description: active_nonrating_request_issue.description,
                                      decision_date: active_nonrating_request_issue.decision_date)).to_not be_nil
        end
      end
    end

    context "Veteran has no ratings" do
      let!(:higher_level_review) do
        HigherLevelReview.create!(
          veteran_file_number: veteran_no_ratings.file_number,
          receipt_date: receipt_date,
          informal_conference: false,
          same_office: false,
          benefit_type: "compensation"
        )
      end
      let(:veteran_no_ratings) do
        Generators::Veteran.build(
          file_number: "55555555",
          first_name: "Nora",
          last_name: "Attings",
          participant_id: "44444444"
        )
      end
      let(:request_issue) do
        create(:request_issue, description: "nonrating issue desc", review_request: higher_level_review)
      end
      let(:rating_ep_claim_id) do
        higher_level_review.end_product_establishments.first.reference_id
      end

      before do
        higher_level_review.create_issues!([request_issue])
        higher_level_review.establish!
      end

      scenario "the Add Issue modal skips directly to Nonrating Issue modal" do
        visit "higher_level_reviews/#{rating_ep_claim_id}/edit"

        expect(page).to have_content("Add / Remove Issues")

        click_intake_add_issue
        add_intake_nonrating_issue(
          category: "Active Duty Adjustments",
          description: "Description for Active Duty Adjustments",
          date: "04/19/2018"
        )

        expect(page).to have_content("2 issues")
      end
    end

    context "when there is a rating end product" do
      let(:contention_ref_id) { "123" }
      let!(:request_issue) do
        create(:request_issue,
               contested_rating_issue_reference_id: "def456",
               contested_rating_issue_profile_date: rating.profile_date,
               review_request: higher_level_review,
               description: "PTSD denied")
      end

      let(:request_issues) { [request_issue] }

      let(:rating_ep_claim_id) do
        EndProductEstablishment.find_by(
          source: higher_level_review,
          code: "030HLRR"
        ).reference_id
      end

      before do
        higher_level_review.create_issues!(request_issues)
        higher_level_review.establish!
      end

      context "has decision issues" do
        let(:contested_decision_issues) { setup_prior_decision_issues(veteran) }

        let(:decision_request_issue) do
          create(
            :request_issue,
            review_request: higher_level_review,
            description: "currently contesting decision issue",
            decision_date: Time.zone.now - 2.days,
            contested_decision_issue_id: contested_decision_issues.first.id
          )
        end

        let!(:request_issue_that_causes_ineligiblity) do
          already_active_hlr = create(:higher_level_review, :with_end_product_establishment)
          create(
            :request_issue,
            review_request: already_active_hlr,
            description: "currently active request issue",
            decision_date: Time.zone.now - 2.days,
            end_product_establishment_id: already_active_hlr.end_product_establishments.first.id,
            contested_decision_issue_id: contested_decision_issues.second.id
          )
        end

        let(:request_issues) { [request_issue, decision_request_issue] }

        it "shows decision isssues and allows adding/removing issues" do
          verify_decision_issues_can_be_added_and_removed(
            "higher_level_reviews/#{rating_ep_claim_id}/edit",
            decision_request_issue,
            higher_level_review,
            contested_decision_issues
          )
        end
      end

      context "with existing request issues contesting decision issues" do
        let(:decision_request_issue) do
          setup_request_issue_with_nonrating_decision_issue(higher_level_review)
        end

        let(:nonrating_decision_request_issue) do
          setup_request_issue_with_rating_decision_issue(
            higher_level_review,
            contested_rating_issue_reference_id: "abc123"
          )
        end

        let(:request_issues) { [request_issue, decision_request_issue, nonrating_decision_request_issue] }

        it "does not remove & readd unedited issues" do
          verify_request_issue_contending_decision_issue_not_readded(
            "higher_level_reviews/#{rating_ep_claim_id}/edit",
            higher_level_review,
            decision_request_issue.decision_issues + nonrating_decision_request_issue.decision_issues
          )
        end
      end

      it "shows request issues and allows adding/removing issues" do
        visit "higher_level_reviews/#{rating_ep_claim_id}/edit"

        expect(page).to have_content("Add / Remove Issues")
        check_row("Form", Constants.INTAKE_FORM_NAMES.higher_level_review)
        check_row("Benefit type", "Compensation")
        check_row("Claimant", "Bob Vance, Spouse (payee code 10)")

        # Check that request issues appear correctly as added issues
        expect(page).to_not have_content("Left knee granted")
        expect(page).to have_content("PTSD denied")

        click_intake_add_issue

        expect(page).to have_content("Add issue 2")
        expect(page).to have_content("Does issue 2 match any of these issues")
        expect(page).to have_content("Left knee granted")
        expect(page).to have_content("PTSD denied")

        # test canceling adding an issue by closing the modal
        safe_click ".close-modal"
        expect(page).to_not have_content("2. Left knee granted")

        # adding an issue should show the issue
        click_intake_add_issue
        add_intake_rating_issue("Left knee granted")
        expect(page).to have_content("2. Left knee granted")
        expect(page).to_not have_content("Notes:")

        # remove existing issue
        click_remove_intake_issue("1")
        click_remove_issue_confirmation
        expect(page).not_to have_content("PTSD denied")

        # re-add to proceed
        click_intake_add_issue
        add_intake_rating_issue("PTSD denied", "I am an issue note")
        expect(page).to have_content("PTSD denied")
        expect(page).to_not have_content("PTSD denied is ineligible")
        expect(page).to have_content("I am an issue note")

        # clicking add issue again should show a disabled radio button for that same rating
        click_intake_add_issue
        expect(page).to have_content("Add issue 3")
        expect(page).to have_content("Does issue 3 match any of these issues")
        expect(page).to have_content("Left knee granted (already selected for issue 1)")
        expect(page).to have_css("input[disabled]", visible: false)

        # Add nonrating issue
        click_intake_no_matching_issues
        add_intake_nonrating_issue(
          category: "Active Duty Adjustments",
          description: "Description for Active Duty Adjustments",
          date: "04/25/2018"
        )
        expect(page).to have_content("3 issues")

        # Add untimely nonrating issue
        click_intake_add_issue
        click_intake_no_matching_issues
        add_intake_nonrating_issue(
          category: "Active Duty Adjustments",
          description: "Another Description for Active Duty Adjustments",
          date: "04/25/2016"
        )
        add_untimely_exemption_response("No", "I am a nonrating exemption note")
        expect(page).to have_content("4 issues")
        expect(page).to have_content("I am a nonrating exemption note")
        expect(page).to have_content("Another Description for Active Duty Adjustments")

        # add unidentified issue
        click_intake_add_issue
        add_intake_unidentified_issue("This is an unidentified issue")
        expect(page).to have_content("5 issues")
        expect(page).to have_content("This is an unidentified issue")
        expect(find_intake_issue_by_number(5)).to have_css(".issue-unidentified")
        expect_ineligible_issue(5)

        # add issue before AMA
        click_intake_add_issue
        add_intake_rating_issue("Non-RAMP Issue before AMA Activation")
        expect(page).to have_content(
          "Non-RAMP Issue before AMA Activation #{Constants.INELIGIBLE_REQUEST_ISSUES.before_ama}"
        )
        expect_ineligible_issue(6)

        # add RAMP issue before AMA
        click_intake_add_issue
        add_intake_rating_issue("Issue before AMA Activation from RAMP")
        expect(page).to have_content("Issue before AMA Activation from RAMP Decision date:")

        safe_click("#button-submit-update")

        expect(page).to have_content("You still have an \"Unidentified\" issue")
        safe_click "#Unidentified-issue-button-id-1"

        expect(page).to have_content("The review originally had 1 issue but now has 7.")

        safe_click "#Number-of-issues-has-changed-button-id-1"
        expect(page).to have_content("Edit Confirmed")

        # assert server has updated data for nonrating and unidentified issues
        active_duty_adjustments_request_issue = RequestIssue.find_by!(
          review_request: higher_level_review,
          issue_category: "Active Duty Adjustments",
          decision_date: 1.month.ago,
          description: "Description for Active Duty Adjustments"
        )

        expect(active_duty_adjustments_request_issue.untimely?).to eq(false)

        another_active_duty_adjustments_request_issue = RequestIssue.find_by!(
          review_request: higher_level_review,
          issue_category: "Active Duty Adjustments",
          description: "Another Description for Active Duty Adjustments"
        )

        expect(another_active_duty_adjustments_request_issue.untimely?).to eq(true)
        expect(another_active_duty_adjustments_request_issue.untimely_exemption?).to eq(false)
        expect(another_active_duty_adjustments_request_issue.untimely_exemption_notes).to_not be_nil

        expect(RequestIssue.find_by(
                 review_request: higher_level_review,
                 description: "This is an unidentified issue"
               )).to_not be_nil

        expect(RequestIssue.find_by(
                 review_request: higher_level_review,
                 ramp_claim_id: "ramp_claim_id"
               )).to_not be_nil

        rating_epe = EndProductEstablishment.find_by!(
          source: higher_level_review,
          code: HigherLevelReview::END_PRODUCT_CODES[:rating]
        )

        nonrating_epe = EndProductEstablishment.find_by!(
          source: higher_level_review,
          code: HigherLevelReview::END_PRODUCT_CODES[:nonrating]
        )

        # expect the remove/re-add to create a new RequestIssue for same RatingIssue
        expect(higher_level_review.reload.request_issues).to_not include(request_issue)
        new_version_of_request_issue = higher_level_review.find_request_issue_by_description(request_issue.description)
        expect(new_version_of_request_issue.contested_rating_issue_reference_id).to eq(
          request_issue.contested_rating_issue_reference_id
        )

        # expect contentions to reflect issue update
        existing_contention = rating_epe.contentions.first
        expect(existing_contention.text).to eq("PTSD denied")
        expect(Fakes::VBMSService).to have_received(:remove_contention!).once.with(existing_contention)

        expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
          veteran_file_number: veteran.file_number,
          claim_id: rating_epe.reference_id,
          contention_descriptions: array_including(
            RequestIssue::UNIDENTIFIED_ISSUE_MSG,
            "Left knee granted",
            "Issue before AMA Activation from RAMP",
            "PTSD denied" # remove and create, both
          ),
          special_issues: [],
          user: current_user
        )

        expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
          veteran_file_number: veteran.file_number,
          claim_id: nonrating_epe.reference_id,
          contention_descriptions: [
            "Active Duty Adjustments - Description for Active Duty Adjustments"
          ],
          special_issues: [],
          user: current_user
        )
      end

      it "enables save button only when dirty" do
        visit "higher_level_reviews/#{rating_ep_claim_id}/edit"

        expect(page).to have_button("Save", disabled: true)

        click_intake_add_issue
        add_intake_rating_issue("Left knee granted")
        expect(page).to have_button("Save", disabled: false)

        click_remove_intake_issue("2")
        click_remove_issue_confirmation
        expect(page).to_not have_content("Left knee granted")
        expect(page).to have_button("Save", disabled: true)
      end

      it "Does not allow save if no issues are selected" do
        visit "higher_level_reviews/#{rating_ep_claim_id}/edit"
        click_remove_intake_issue("1")
        click_remove_issue_confirmation

        expect(page).to have_button("Save", disabled: true)
      end

      scenario "shows error message if an update is in progress" do
        RequestIssuesUpdate.create!(
          review: higher_level_review,
          user: current_user,
          before_request_issue_ids: [request_issue.id],
          after_request_issue_ids: [request_issue.id],
          attempted_at: Time.zone.now,
          submitted_at: Time.zone.now,
          processed_at: nil
        )

        visit "higher_level_reviews/#{rating_ep_claim_id}/edit"
        click_intake_add_issue
        add_intake_rating_issue("Left knee granted")
        safe_click("#button-submit-update")

        expect(page).to have_content("The review originally had 1 issue but now has 2.")

        safe_click ".confirm"

        expect(page).to have_content("Previous update not yet done processing")
      end

      it "updates selected issues" do
        allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
        allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
        allow(Fakes::VBMSService).to receive(:associate_rating_request_issues!).and_call_original
        allow(Fakes::VBMSService).to receive(:remove_contention!).and_call_original

        visit "higher_level_reviews/#{rating_ep_claim_id}/edit"
        click_remove_intake_issue("1")
        click_remove_issue_confirmation
        click_intake_add_issue
        add_intake_rating_issue("Left knee granted")

        expect(page).to have_button("Save", disabled: false)

        safe_click("#button-submit-update")

        expect(page).to have_current_path(
          "/higher_level_reviews/#{rating_ep_claim_id}/edit/confirmation"
        )

        # reload to verify that the new issues populate the form
        visit "higher_level_reviews/#{rating_ep_claim_id}/edit"
        expect(page).to have_content("Left knee granted")
        expect(page).to_not have_content("PTSD denied")

        # assert server has updated data
        new_request_issue = higher_level_review.reload.request_issues.first
        expect(new_request_issue.description).to eq("Left knee granted")
        expect(request_issue.reload.review_request_id).to be_nil
        expect(request_issue.removed_at).to eq(Time.zone.now)
        expect(new_request_issue.rating_issue_associated_at).to eq(Time.zone.now)

        # expect contentions to reflect issue update
        expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
          veteran_file_number: veteran.file_number,
          claim_id: rating_ep_claim_id,
          contention_descriptions: ["Left knee granted"],
          special_issues: [],
          user: current_user
        )
        expect(Fakes::VBMSService).to have_received(:associate_rating_request_issues!).with(
          claim_id: rating_ep_claim_id,
          rating_issue_contention_map: {
            new_request_issue.contested_rating_issue_reference_id => new_request_issue.contention_reference_id
          }
        )
        expect(Fakes::VBMSService).to have_received(:remove_contention!).once
      end

      feature "cancel edits" do
        def click_cancel(visit_page)
          visit "higher_level_reviews/#{rating_ep_claim_id}/edit#{visit_page}"
          click_on "Cancel"
          correct_path = "/higher_level_reviews/#{rating_ep_claim_id}/edit/cancel"
          expect(page).to have_current_path(correct_path)
          expect(page).to have_content("Edit Canceled")
          expect(page).to have_content(Constants.INTAKE_FORM_NAMES.higher_level_review)
        end

        scenario "from landing page" do
          click_cancel("/")
        end
      end

      feature "with cleared end product" do
        let!(:cleared_end_product) do
          create(:end_product_establishment,
                 source: higher_level_review,
                 synced_status: "CLR")
        end

        scenario "prevents edits on eps that have cleared" do
          visit "higher_level_reviews/#{rating_ep_claim_id}/edit/"
          expect(page).to have_current_path("/higher_level_reviews/#{rating_ep_claim_id}/edit/cleared_eps")
          expect(page).to have_content("Issues Not Editable")
          expect(page).to have_content(Constants.INTAKE_FORM_NAMES.higher_level_review)
        end
      end
    end
  end

  context "Supplemental claims" do
    let(:is_dta_error) { false }
    let(:benefit_type) { "compensation" }

    let!(:supplemental_claim) do
      SupplementalClaim.create!(
        veteran_file_number: veteran.file_number,
        receipt_date: receipt_date,
        benefit_type: benefit_type,
        is_dta_error: is_dta_error,
        veteran_is_not_claimant: true
      )
    end

    # create intake
    let!(:intake) do
      Intake.create!(
        user_id: current_user.id,
        detail: supplemental_claim,
        veteran_file_number: veteran.file_number,
        started_at: Time.zone.now,
        completed_at: Time.zone.now,
        completion_status: "success",
        type: "SupplementalClaimIntake"
      )
    end

    let(:rating_ep_claim_id) do
      EndProductEstablishment.find_by(
        source: supplemental_claim,
        code: "040SCR"
      ).reference_id
    end

    before do
      supplemental_claim.create_claimants!(participant_id: "5382910292", payee_code: "10")

      allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original

      allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return(
        first_name: "BOB",
        last_name: "VANCE",
        ptcpnt_id: "5382910292",
        relationship_type: "Spouse"
      )
    end

    context "when there is a non-rating end product" do
      let!(:nonrating_request_issue) do
        RequestIssue.create!(
          review_request: supplemental_claim,
          issue_category: "Military Retired Pay",
          description: "nonrating description",
          contention_reference_id: "1234",
          decision_date: 1.month.ago
        )
      end

      before do
        supplemental_claim.create_issues!([nonrating_request_issue])
        supplemental_claim.establish!
      end

      context "when it is created due to a DTA error" do
        let(:is_dta_error) { true }

        it "cannot be edited" do
          nonrating_dta_claim_id = EndProductEstablishment.find_by(
            source: supplemental_claim,
            code: "040HDENR"
          ).reference_id

          visit "supplemental_claims/#{nonrating_dta_claim_id}/edit"
          expect(page).to have_content("Issues Not Editable")
        end

        context "when benefit type is pension" do
          let(:benefit_type) { "pension" }
          it "cannot be edited" do
            nonrating_dta_claim_id = EndProductEstablishment.find_by(
              source: supplemental_claim,
              code: "040HDENRPMC"
            ).reference_id

            visit "supplemental_claims/#{nonrating_dta_claim_id}/edit"
            expect(page).to have_content("Issues Not Editable")
          end
        end
      end

      it "shows the Supplemental Claim Edit page with a nonrating claim id" do
        nonrating_ep_claim_id = EndProductEstablishment.find_by(
          source: supplemental_claim,
          code: "040SCNR"
        ).reference_id
        visit "supplemental_claims/#{nonrating_ep_claim_id}/edit"

        expect(page).to have_content("Military Retired Pay")

        click_intake_add_issue
        click_intake_no_matching_issues
        add_intake_nonrating_issue(
          category: "Active Duty Adjustments",
          description: "A description!",
          date: "04/25/2018"
        )

        safe_click("#button-submit-update")

        expect(page).to have_content("The review originally had 1 issue but now has 2.")
        safe_click ".confirm"

        expect(page).to have_current_path(
          "/supplemental_claims/#{nonrating_ep_claim_id}/edit/confirmation"
        )
        expect(page).to have_content("Edit Confirmed")
      end
    end

    context "when there is a rating end product" do
      let(:request_issue) do
        RequestIssue.create!(
          contested_rating_issue_reference_id: "def456",
          contested_rating_issue_profile_date: rating.profile_date,
          review_request: supplemental_claim,
          description: "PTSD denied"
        )
      end

      let(:request_issues) { [request_issue] }

      before do
        supplemental_claim.create_issues!(request_issues)
        supplemental_claim.establish!
      end

      context "when it is created due to a DTA error" do
        let(:is_dta_error) { true }

        it "cannot be edited" do
          rating_dta_claim_id = EndProductEstablishment.find_by(
            source: supplemental_claim,
            code: "040HDER"
          ).reference_id

          visit "supplemental_claims/#{rating_dta_claim_id}/edit"
          expect(page).to have_content("Issues Not Editable")
        end

        context "when benefit type is pension" do
          let(:benefit_type) { "pension" }
          it "cannot be edited" do
            rating_dta_claim_id = EndProductEstablishment.find_by(
              source: supplemental_claim,
              code: "040HDERPMC"
            ).reference_id

            visit "supplemental_claims/#{rating_dta_claim_id}/edit"
            expect(page).to have_content("Issues Not Editable")
          end
        end
      end

      it "shows request issues and allows adding/removing issues" do
        visit "supplemental_claims/#{rating_ep_claim_id}/edit"

        # Check that request issues appear correctly as added issues
        expect(page).to_not have_content("Left knee granted")
        expect(page).to have_content("PTSD denied")

        expect(page).to have_content("Add / Remove Issues")
        check_row("Form", Constants.INTAKE_FORM_NAMES.supplemental_claim)
        check_row("Benefit type", "Compensation")
        check_row("Claimant", "Bob Vance, Spouse (payee code 10)")

        click_intake_add_issue

        expect(page).to have_content("Add issue 2")
        expect(page).to have_content("Does issue 2 match any of these issues")
        expect(page).to have_content("Left knee granted")
        expect(page).to have_content("PTSD denied")

        # test canceling adding an issue by closing the modal
        safe_click ".close-modal"
        expect(page).to_not have_content("2. Left knee granted")

        # adding an issue should show the issue
        click_intake_add_issue
        add_intake_rating_issue("Left knee granted")

        expect(page).to have_content("2. Left knee granted")
        expect(page).to_not have_content("Notes:")
        click_remove_intake_issue("1")

        # expect a pop up
        expect(page).to have_content("Are you sure you want to remove this issue?")
        click_remove_issue_confirmation

        expect(page).not_to have_content("PTSD denied")

        # re-add to proceed
        click_intake_add_issue
        add_intake_rating_issue("PTSD denied", "I am an issue note")
        expect(page).to have_content("2. PTSD denied")
        expect(page).to have_content("I am an issue note")

        # clicking add issue again should show a disabled radio button for that same rating
        click_intake_add_issue
        expect(page).to have_content("Add issue 3")
        expect(page).to have_content("Does issue 3 match any of these issues")
        expect(page).to have_content("Left knee granted (already selected for issue 1)")
        expect(page).to have_css("input[disabled]", visible: false)

        # Add nonrating issue
        click_intake_no_matching_issues
        add_intake_nonrating_issue(
          category: "Active Duty Adjustments",
          description: "Description for Active Duty Adjustments",
          date: "04/25/2018"
        )
        expect(page).to have_content("3 issues")

        # add unidentified issue
        click_intake_add_issue
        add_intake_unidentified_issue("This is an unidentified issue")
        expect(page).to have_content("4 issues")
        expect(page).to have_content("This is an unidentified issue")
      end

      context "when veteran has active nonrating request issues" do
        let(:another_higher_level_review) do
          create(:higher_level_review,
                 veteran_file_number: veteran.file_number,
                 benefit_type: "compensation")
        end

        let!(:active_nonrating_request_issue) do
          create(:request_issue,
                 :nonrating,
                 review_request: another_higher_level_review)
        end

        before do
          another_higher_level_review.create_issues!([active_nonrating_request_issue])
        end

        scenario "shows ineligibility message and saves conflicting request issue id" do
          visit "supplemental_claims/#{rating_ep_claim_id}/edit"
          click_intake_add_issue
          click_intake_no_matching_issues

          fill_in "Issue category", with: active_nonrating_request_issue.issue_category
          find("#issue-category").send_keys :enter
          expect(page).to have_content("Does issue 2 match any of the issues actively being reviewed?")
          expect(page).to have_content("#{active_nonrating_request_issue.issue_category}: " \
                                       "#{active_nonrating_request_issue.description}")
          add_active_intake_nonrating_issue(active_nonrating_request_issue.issue_category)
          expect(page).to have_content("#{active_nonrating_request_issue.issue_category} -" \
                                       " #{active_nonrating_request_issue.description}" \
                                       " is ineligible because it's already under review as a Higher-Level Review")

          safe_click("#button-submit-update")
          safe_click ".confirm"
          expect(page).to have_content("Edit Confirmed")

          expect(RequestIssue.find_by(review_request: supplemental_claim,
                                      issue_category: active_nonrating_request_issue.issue_category,
                                      ineligible_due_to: active_nonrating_request_issue.id,
                                      ineligible_reason: "duplicate_of_nonrating_issue_in_active_review",
                                      description: active_nonrating_request_issue.description,
                                      decision_date: active_nonrating_request_issue.decision_date)).to_not be_nil
        end
      end

      context "has decision issues" do
        let(:contested_decision_issues) { setup_prior_decision_issues(veteran) }
        let(:decision_request_issue) do
          create(
            :request_issue,
            review_request: supplemental_claim,
            description: "currently contesting decision issue",
            decision_date: Time.zone.now - 2.days,
            contested_decision_issue_id: contested_decision_issues.first.id
          )
        end

        let(:request_issues) { [request_issue, decision_request_issue] }

        let!(:request_issue_that_causes_ineligiblity) do
          already_active_hlr = create(:higher_level_review, :with_end_product_establishment)
          create(
            :request_issue,
            review_request: already_active_hlr,
            description: "currently active request issue",
            decision_date: Time.zone.now - 2.days,
            end_product_establishment_id: already_active_hlr.end_product_establishments.first.id,
            contested_decision_issue_id: contested_decision_issues.second.id
          )
        end

        it "shows decision isssues and allows adding/removing issues" do
          verify_decision_issues_can_be_added_and_removed(
            "supplemental_claims/#{rating_ep_claim_id}/edit",
            decision_request_issue,
            supplemental_claim,
            contested_decision_issues
          )
        end
      end

      context "with existing request issues contesting decision issues" do
        let(:decision_request_issue) do
          setup_request_issue_with_nonrating_decision_issue(supplemental_claim)
        end

        let(:nonrating_decision_request_issue) do
          setup_request_issue_with_rating_decision_issue(
            supplemental_claim,
            contested_rating_issue_reference_id: "abc123"
          )
        end

        let(:request_issues) { [request_issue, decision_request_issue, nonrating_decision_request_issue] }

        it "does not remove & readd unedited issues" do
          verify_request_issue_contending_decision_issue_not_readded(
            "supplemental_claims/#{rating_ep_claim_id}/edit",
            supplemental_claim,
            decision_request_issue.decision_issues + nonrating_decision_request_issue.decision_issues
          )
        end
      end

      it "enables save button only when dirty" do
        visit "supplemental_claims/#{rating_ep_claim_id}/edit"

        expect(page).to have_button("Save", disabled: true)

        click_intake_add_issue
        add_intake_rating_issue("Left knee granted")

        expect(page).to have_button("Save", disabled: false)

        click_remove_intake_issue("2")
        click_remove_issue_confirmation

        expect(page).to_not have_content("Left knee granted")
        expect(page).to have_button("Save", disabled: true)
      end

      it "Does not allow save if no issues are selected" do
        visit "supplemental_claims/#{rating_ep_claim_id}/edit"
        click_remove_intake_issue("1")
        click_remove_issue_confirmation

        expect(page).to have_button("Save", disabled: true)
      end

      scenario "shows error message if an update is in progress" do
        RequestIssuesUpdate.create!(
          review: supplemental_claim,
          user: current_user,
          before_request_issue_ids: [request_issue.id],
          after_request_issue_ids: [request_issue.id],
          attempted_at: Time.zone.now,
          submitted_at: Time.zone.now,
          processed_at: nil
        )

        visit "supplemental_claims/#{rating_ep_claim_id}/edit"
        click_intake_add_issue
        add_intake_rating_issue("Left knee granted")
        safe_click("#button-submit-update")

        expect(page).to have_content("The review originally had 1 issue but now has 2.")
        safe_click ".confirm"

        expect(page).to have_content("Previous update not yet done processing")
      end

      it "updates selected issues" do
        allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
        allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
        allow(Fakes::VBMSService).to receive(:associate_rating_request_issues!).and_call_original
        allow(Fakes::VBMSService).to receive(:remove_contention!).and_call_original

        visit "supplemental_claims/#{rating_ep_claim_id}/edit"
        click_remove_intake_issue("1")
        click_remove_issue_confirmation
        click_intake_add_issue
        add_intake_rating_issue("Left knee granted")

        expect(page).to have_button("Save", disabled: false)

        safe_click("#button-submit-update")

        expect(page).to have_current_path(
          "/supplemental_claims/#{rating_ep_claim_id}/edit/confirmation"
        )

        # reload to verify that the new issues populate the form
        visit "supplemental_claims/#{rating_ep_claim_id}/edit"
        expect(page).to have_content("Left knee granted")
        expect(page).to_not have_content("PTSD denied")

        # assert server has updated data
        new_request_issue = supplemental_claim.reload.request_issues.first
        expect(new_request_issue.description).to eq("Left knee granted")
        expect(request_issue.reload.review_request_id).to be_nil
        expect(request_issue.removed_at).to eq(Time.zone.now)
        expect(new_request_issue.rating_issue_associated_at).to eq(Time.zone.now)

        # expect contentions to reflect issue update
        expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
          veteran_file_number: veteran.file_number,
          claim_id: rating_ep_claim_id,
          contention_descriptions: ["Left knee granted"],
          special_issues: [],
          user: current_user
        )
        expect(Fakes::VBMSService).to have_received(:associate_rating_request_issues!).with(
          claim_id: rating_ep_claim_id,
          rating_issue_contention_map: {
            new_request_issue.contested_rating_issue_reference_id => new_request_issue.contention_reference_id
          }
        )
        expect(Fakes::VBMSService).to have_received(:remove_contention!).once
      end

      feature "cancel edits" do
        def click_cancel(visit_page)
          visit "supplemental_claims/#{rating_ep_claim_id}/edit#{visit_page}"
          click_on "Cancel"
          correct_path = "/supplemental_claims/#{rating_ep_claim_id}/edit/cancel"
          expect(page).to have_current_path(correct_path)
          expect(page).to have_content("Edit Canceled")
          expect(page).to have_content(Constants.INTAKE_FORM_NAMES.supplemental_claim)
        end

        scenario "from landing page" do
          click_cancel("/")
        end
      end

      feature "with cleared end product" do
        let!(:cleared_end_product) do
          create(:end_product_establishment,
                 source: supplemental_claim,
                 synced_status: "CLR")
        end

        scenario "prevents edits on eps that have cleared" do
          visit "supplemental_claims/#{rating_ep_claim_id}/edit/"
          expect(page).to have_current_path("/supplemental_claims/#{rating_ep_claim_id}/edit/cleared_eps")
          expect(page).to have_content("Issues Not Editable")
          expect(page).to have_content(Constants.INTAKE_FORM_NAMES.supplemental_claim)
        end
      end
    end
  end
end
