# frozen_string_literal: true

FactoryBot.define do
  factory :legacy_appeal do
    transient do
      vacols_case { nil }
      veteran_address { nil }
    end

    vacols_id { vacols_case&.bfkey || "123456" }
    vbms_id { vacols_case&.bfcorlid }

    after(:create) do |appeal, evaluator|
      if evaluator.veteran_address.present?
        veteran = create(:veteran, file_number: appeal.sanitized_vbms_id)

        (BGSService.address_records ||= {}).update(veteran.participant_id => evaluator.veteran_address)
      end
    end

    trait :with_schedule_hearing_tasks do
      after(:create) do |appeal, _evaluator|
        root_task = RootTask.find_or_create_by!(appeal: appeal, assigned_to: Bva.singleton)
        ScheduleHearingTask.create!(appeal: appeal, parent: root_task)
      end
    end

    trait :with_judge_assign_task do
      after(:create) do |appeal, _evaluator|
        root_task = RootTask.find_or_create_by!(appeal: appeal, assigned_to: Bva.singleton)
        judge = User.find_or_create_by(css_id: "BVAAABSHIRE", station_id: 101)
        JudgeAssignTask.create!(appeal: appeal,
                                parent: root_task,
                                assigned_at: Time.zone.now,
                                assigned_to: judge)
      end
    end

    trait :with_veteran do
      after(:create) do |legacy_appeal, evaluator|
        veteran = create(
          :veteran,
          file_number: legacy_appeal.veteran_file_number,
          first_name: "Bob",
          last_name: "Smith"
        )

        if evaluator.vacols_case
          evaluator.vacols_case.correspondent.snamef = veteran.first_name
          evaluator.vacols_case.correspondent.snamel = veteran.last_name
          evaluator.vacols_case.correspondent.ssalut = "PhD"
          evaluator.vacols_case.correspondent.save
        end
      end
    end

    trait :with_veteran_address do
      veteran_address {
        {
          addrs_one_txt: FakeConstants.BGS_SERVICE.DEFAULT_ADDRESS_LINE_1,
          addrs_two_txt: FakeConstants.BGS_SERVICE.DEFAULT_ADDRESS_LINE_2,
          addrs_three_txt: FakeConstants.BGS_SERVICE.DEFAULT_ADDRESS_LINE_3,
          city_nm: FakeConstants.BGS_SERVICE.DEFAULT_CITY,
          cntry_nm: FakeConstants.BGS_SERVICE.DEFAULT_COUNTRY,
          postal_cd: FakeConstants.BGS_SERVICE.DEFAULT_STATE,
          zip_prefix_nbr: FakeConstants.BGS_SERVICE.DEFAULT_ZIP
        }
      }
    end
  end
end
