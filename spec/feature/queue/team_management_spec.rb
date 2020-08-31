# frozen_string_literal: true

RSpec.feature "Team management page", :postgres do
  let(:user) { create(:user) }

  before do
    Bva.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  describe "Navigation to team management page" do
    context "when user is not in Bva organization" do
      let(:non_bva_user) { create(:user) }
      before { User.authenticate!(user: non_bva_user) }

      scenario "link does not appear in dropdown menu" do
        visit("/queue")
        find("#menu-trigger").click
        expect(page).to_not have_content(COPY::TEAM_MANAGEMENT_PAGE_DROPDOWN_LINK)
      end

      scenario "user is denied access to team management page" do
        visit("/team_management")
        expect(page).to have_content(COPY::UNAUTHORIZED_PAGE_ACCESS_MESSAGE)
        expect(page.current_path).to eq("/unauthorized")
      end
    end

    context "when user is in Bva organization" do
      scenario "link appears in dropdown menu" do
        visit("/queue")

        find("#menu-trigger").click
        expect(page).to have_content(COPY::TEAM_MANAGEMENT_PAGE_DROPDOWN_LINK)
      end

      scenario "user can view the team management page" do
        visit("/team_management")
        expect(page).to have_content("Judge teams")
        expect(page).to have_content("VSOs")
        expect(page).to have_content("Private Bar")
        expect(page).to have_content("Other teams")
      end
    end

    context "when user is a dvc" do
      before do
        dvc = create(:user)
        DvcTeam.create_for_dvc(dvc)
        User.authenticate!(user: dvc)
      end

      scenario "link appears in dropdown menu" do
        visit("/queue")

        find("#menu-trigger").click
        expect(page).to have_content(COPY::TEAM_MANAGEMENT_PAGE_DROPDOWN_LINK)
      end

      scenario "user can view the team management page, but only judges" do
        visit("/team_management")
        expect(page).to have_content("Judge teams")
        expect(page).to have_no_content("VSOs")
        expect(page).to have_no_content("Private Bar")
        expect(page).to have_no_content("Other teams")
      end
    end
  end
end
