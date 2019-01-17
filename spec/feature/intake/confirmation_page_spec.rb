require "support/intake_helpers"

feature "Intake Confirmation Page" do
  include IntakeHelpers

  before { setup_intake_flags }
  after { teardown_intake_flags }

  let!(:current_user) { User.authenticate!(roles: ["Mail Intake"]) }
  let(:before_ama_date) { 3.years.ago }

  describe "when completing a claim review" do
    describe "Confirmation copy" do
      [:higher_level_review, :supplemental_claim].each do |claim_review_type|
        describe "given a #{claim_review_type}" do
          it "does not show edit in VBMS or tracked item if there is no End Product" do
            if claim_review_type == :supplemental_claim
              start_supplemental_claim(create(:veteran))
            else
              start_higher_level_review(create(:veteran), informal_conference: true)
            end

            visit "/intake"
            click_intake_continue
            click_intake_add_issue
            # Add only one ineligible issue, so there will be no eligible issues
            add_intake_nonrating_issue(date: before_ama_date.strftime("%m/%d/%Y"))
            add_untimely_exemption_response("Yes") if claim_review_type == :higher_level_review
            click_intake_finish
            expect(page).to have_content("Intake completed")
            expect(page).to_not have_content("If you need to edit this, go to VBMS claim details")
            expect(page).to_not have_content("Informal Conference Tracked Item")
          end

          it "shows EP related content if there is an end product created" do
            if claim_review_type == :supplemental_claim
              start_supplemental_claim(create(:veteran))
            else
              start_higher_level_review(create(:veteran), informal_conference: true)
            end

            visit "/intake"
            click_intake_continue
            click_intake_add_issue
            # Add an eligible issue
            add_intake_nonrating_issue(date: 6.months.ago.strftime("%m/%d/%Y"))
            click_intake_finish
            expect(page).to have_content("Intake completed")
            expect(page).to have_content("Nonrating EP is being established")
            expect(page).to have_content("If you need to edit this, go to VBMS claim details")
            expect(page).to have_content("Tracked Item") if claim_review_type == :higher_level_review
          end
        end
      end
    end
  end
end
