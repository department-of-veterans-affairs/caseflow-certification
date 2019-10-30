# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe JudgeTeamRoleChecker, :postgres do
  describe ".judge_teams_with_incorrect_number_of_leads" do
    subject { JudgeTeamRoleChecker.new.judge_teams_with_incorrect_number_of_leads }

    # Variables in cases to check:
    # - number of JudgeTeams: 0, 1, many
    # - if team has a JudgeTeamLead: 0, 1, many
    # - if team has other members: 0, 1, many

    context "when there is no JudgeTeam" do
      it "returns no records/errors" do
        expect(subject.empty?).to eq(true)
      end
    end

    # 24 is insignificant, just a moderately large number. 2 because always want at least 2 non leads.
    many_non_leads_count = rand(2..24)
    non_lead_member_counts = [0, 1, many_non_leads_count]

    context "when there is 1 JudgeTeam" do
      let!(:judge_teams) { [judge_team] }

      context "when team has no JudgeTeamLead" do
        # All sub-cases should identify the team with missing JudgeTeamLead
        let!(:judge_team) { create(:judge_team) }

        non_lead_member_counts.each do |non_lead_member_count|
          context "when team has #{non_lead_member_count} other non-JudgeTeamLead members" do
            before do
              # Add non-leads to team
              create_list(:user, non_lead_member_count) do |user|
                OrganizationsUser.add_user_to_organization(user, judge_team)
              end
            end

            it "identifies team with missing JudgeTeamLead" do
              expect(subject).to eq(judge_teams)
            end
          end
        end
      end

      context "when team has 1 JudgeTeamLead" do
        # All sub-cases should not report any error
        let!(:judge_team) { create(:judge_team, :has_judge_team_lead) }

        non_lead_member_counts.each do |non_lead_member_count|
          context "when team has #{non_lead_member_count} other non-JudgeTeamLead members" do
            before do
              # Add non-leads to team
              create_list(:user, non_lead_member_count) do |user|
                OrganizationsUser.add_user_to_organization(user, judge_team)
              end
            end

            it "does not report any records/errors" do
              expect(subject.empty?).to eq(true)
            end
          end
        end
      end

      context "when there are 2 JudgeTeamLeads" do
        # All sub-cases should identify the team with missing JudgeTeamLead
        let!(:judge_team) { create(:judge_team, :has_two_judge_team_lead) }

        non_lead_member_counts.each do |non_lead_member_count|
          context "when team has #{non_lead_member_count} other non-JudgeTeamLead members" do
            before do
              # Add non-leads to team
              create_list(:user, non_lead_member_count) do |user|
                OrganizationsUser.add_user_to_organization(user, judge_team)
              end
            end

            it "identifies team with missing JudgeTeamLead" do
              expect(subject).to eq(judge_teams)
            end
          end
        end
      end
    end

    context "when there are 2 JudgeTeams" do
      let!(:judge_teams) { [judge_team1, judge_team2] }

      context "when all teams have no JudgeTeamLead" do
        # All sub-cases should identify the team with missing JudgeTeamLead
        let!(:judge_team1) { create(:judge_team) }
        let!(:judge_team2) { create(:judge_team) }

        non_lead_member_counts.each do |non_lead_member_count|
          context "when team2 has #{non_lead_member_count} other non-JudgeTeamLead members" do
            before do
              # Add non-leads to team
              create_list(:user, non_lead_member_count) do |user|
                OrganizationsUser.add_user_to_organization(user, judge_team2)
              end
            end

            it "identifies team with missing JudgeTeamLead" do
              expect(subject).to eq(judge_teams)
            end
          end
        end
      end

      context "when only team1 has 1 JudgeTeamLead" do
        let!(:judge_team1) { create(:judge_team, :has_judge_team_lead) }
        let!(:judge_team2) { create(:judge_team) }

        non_lead_member_counts.each do |non_lead_member_count|
          context "when team2 has #{non_lead_member_count} other non-JudgeTeamLead members" do
            before do
              # Add non-leads to team
              create_list(:user, non_lead_member_count) do |user|
                OrganizationsUser.add_user_to_organization(user, judge_team2)
              end
            end

            it "identifies the team with missing JudgeTeamLead" do
              expect(subject).to eq([judge_team2])
            end
          end
        end
      end

      context "when one team has 2 JudgeTeamLeads and other team has none" do
        let!(:judge_team1) { create(:judge_team, :has_two_judge_team_lead) }
        let!(:judge_team2) { create(:judge_team) }

        non_lead_member_counts.each do |non_lead_member_count|
          context "when team2 has #{non_lead_member_count} other non-JudgeTeamLead members" do
            before do
              # Add non-leads to team
              create_list(:user, non_lead_member_count) do |user|
                OrganizationsUser.add_user_to_organization(user, judge_team2)
              end
            end

            it "identifies both teams as problematic" do
              expect(subject).to eq(judge_teams)
            end
          end
        end
      end
    end
  end
end
