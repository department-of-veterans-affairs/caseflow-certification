# frozen_string_literal: true

FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "ORG_#{n}" }
    sequence(:url) { |n| "org_queue_#{n}" }

    factory :vso, class: Vso do
      type { Vso.name }
    end

    factory :field_vso, class: FieldVso do
      type { FieldVso.name }
    end

    factory :private_bar, class: PrivateBar do
      type { PrivateBar.name }
    end

    factory :judge_team, class: JudgeTeam do
      type { JudgeTeam.name }

      trait :has_judge_team_lead do
        after(:create) do |judge_team|
          #judge_team_lead.create()
          user = create(:user)
          org_user = OrganizationsUser.add_user_to_organization(user, judge_team)
          JudgeTeamLead.create!(org_user)
        end
      end
    end

    factory :bva do
      type { "Bva" }
    end

    factory :business_line, class: BusinessLine do
      type { "BusinessLine" }
    end

    factory :hearings_management do
      type { "HearingsManagement" }
      name { "Hearings Management" }
    end
  end
end
