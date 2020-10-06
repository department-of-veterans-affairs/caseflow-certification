# frozen_string_literal: true

FactoryBot.define do
  factory :appeal do
    docket_type { Constants.AMA_DOCKETS.evidence_submission }
    established_at { Time.zone.now }
    receipt_date { Time.zone.yesterday }
    sequence(:veteran_file_number, 500_000_000)
    uuid { SecureRandom.uuid }

    after(:build) do |appeal, evaluator|
      if evaluator.veteran
        appeal.veteran_file_number = evaluator.veteran.file_number
      end

      Fakes::VBMSService.document_records ||= {}
      Fakes::VBMSService.document_records[appeal.veteran_file_number] = evaluator.documents
    end

    # Appeal's after_save interferes with explicit updated_at values
    after(:create) do |appeal, evaluator|
      appeal.touch(time: evaluator.updated_at) if evaluator.try(:updated_at)
    end

    after(:create) do |appeal, _evaluator|
      appeal.request_issues.each do |issue|
        issue.decision_review = appeal
        issue.save
      end
    end

    after(:create) do |appeal, evaluator|
      if !appeal.claimants.empty?
        appeal.claimants.each do |claimant|
          claimant.decision_review = appeal
          claimant.save
        end
      elsif evaluator.number_of_claimants
        claimant_class_name = appeal.veteran_is_not_claimant ? "DependentClaimant" : "VeteranClaimant"
        create_list(
          :claimant,
          evaluator.number_of_claimants,
          decision_review: appeal,
          type: claimant_class_name
        )
      else
        create(
          :claimant,
          participant_id: appeal.veteran.participant_id,
          decision_review: appeal,
          payee_code: "00",
          type: "VeteranClaimant"
        )
      end
    end

    transient do
      active_task_assigned_at { Time.zone.now }
    end

    transient do
      associated_attorney do
        judge = User.find_or_create_by(css_id: "BVAAABSHIRE", station_id: 101) do |user|
          user.full_name = "BVAAABSHIRE"
        end
        judge_team = JudgeTeam.for_judge(judge) || JudgeTeam.create_for_judge(judge)
        attorney = User.find_or_create_by(css_id: "BVAEERDMAN", station_id: 101) do |user|
          user.full_name = "BVAEERDMAN"
        end
        judge_team.add_user(attorney)
        create(:staff, :attorney_role, sdomainid: attorney.css_id)

        attorney
      end
    end

    transient do
      associated_judge do
        judge = User.find_or_create_by(css_id: "BVAAABSHIRE", station_id: 101) do |user|
          user.full_name = "BVAAABSHIRE"
        end
        JudgeTeam.for_judge(judge) || JudgeTeam.create_for_judge(judge)
        create(:staff, :judge_role, sdomainid: judge.css_id)

        judge
      end
    end

    transient do
      documents { [] }
    end

    transient do
      number_of_claimants { nil }
    end

    transient do
      veteran do
        Veteran.find_by(file_number: veteran_file_number) || create(:veteran, file_number: veteran_file_number)
      end
    end

    trait :hearing_docket do
      docket_type { Constants.AMA_DOCKETS.hearing }
    end

    trait :evidence_submission_docket do
      docket_type { Constants.AMA_DOCKETS.evidence_submission }
    end

    trait :direct_review_docket do
      docket_type { Constants.AMA_DOCKETS.direct_review }
    end

    trait :held_hearing do
      transient do
        adding_user { nil }
      end

      after(:create) do |appeal, evaluator|
        create(:hearing, judge: nil, disposition: "held", appeal: appeal, adding_user: evaluator.adding_user)
      end
    end

    trait :tied_to_judge do
      transient do
        tied_judge { nil }
      end

      after(:create) do |appeal, evaluator|
        hearing_day = create(
          :hearing_day,
          scheduled_for: 1.day.ago,
          created_by: evaluator.tied_judge,
          updated_by: evaluator.tied_judge
        )
        Hearing.find_by(disposition: Constants.HEARING_DISPOSITION_TYPES.held, appeal: appeal).update!(
          judge: evaluator.tied_judge,
          hearing_day: hearing_day
        )
      end
    end

    trait :outcoded do
      after(:create) do |appeal, _evaluator|
        appeal.create_tasks_on_intake_success!
        appeal.root_task.update!(status: Constants.TASK_STATUSES.completed)
      end
    end

    trait :advanced_on_docket_due_to_age do
      after(:create) do |appeal, _evaluator|
        appeal.claimants = [create(:claimant, :advanced_on_docket_due_to_age, decision_review: appeal)]
      end
    end

    trait :advanced_on_docket_due_to_motion do
      # the appeal has to be established before the motion is created to apply to it.
      established_at { Time.zone.now - 1 }
      after(:create) do |appeal|
        # Create an appeal with two claimants, one with a denied AOD motion
        # and one with a granted motion. The appeal should still be counted as AOD. Appeals only support one claimant,
        # so set the aod claimant as the last claimant on the appeal (and create it last)
        another_claimant = create(:claimant, decision_review: appeal)
        create(:advance_on_docket_motion, person: another_claimant.person, granted: false, appeal: appeal)

        claimant = create(:claimant, decision_review: appeal)
        create(:advance_on_docket_motion, person: claimant.person, granted: true, appeal: appeal)

        appeal.claimants = [another_claimant, claimant]
      end
    end

    trait :cancelled do
      after(:create) do |appeal, _evaluator|
        # make sure a request issue exists, then mark all removed
        create(:request_issue, decision_review: appeal)
        appeal.reload.request_issues.each(&:remove!)

        # Cancel the task tree
        root_task = RootTask.find_or_create_by!(appeal: appeal, assigned_to: Bva.singleton)
        root_task.cancel_task_and_child_subtasks
      end
    end

    trait :denied_advance_on_docket do
      established_at { Time.zone.yesterday }
      after(:create) do |appeal|
        appeal.claimants { [create(:claimant, decision_review: appeal)] }
        create(:advance_on_docket_motion, person: appeal.claimants.last.person, granted: false, appeal: appeal)
      end
    end

    trait :inapplicable_aod_motion do
      after(:create) do |appeal|
        appeal.claimants { [create(:claimant, decision_review: appeal)] }
        create(:advance_on_docket_motion, person: appeal.claimants.last.person, granted: false, appeal: appeal)
      end
    end

    trait :with_schedule_hearing_tasks do
      after(:create) do |appeal, _evaluator|
        root_task = RootTask.find_or_create_by!(appeal: appeal, assigned_to: Bva.singleton)
        ScheduleHearingTask.create!(appeal: appeal, parent: root_task)
      end
    end

    ## Appeal with a realistic task tree
    ## Appeal has finished intake
    trait :with_post_intake_tasks do
      after(:create) do |appeal, _evaluator|
        appeal.create_tasks_on_intake_success!
      end
    end

    ## Appeal with a realistic task tree
    ## The appeal is ready for distribution by the ACD
    trait :ready_for_distribution do
      with_post_intake_tasks
      after(:create) do |appeal, _evaluator|
        distribution_tasks = appeal.tasks.select { |task| task.is_a?(DistributionTask) }
        (distribution_tasks.flat_map(&:descendants) - distribution_tasks).each(&:completed!)
      end
    end

    ## Appeal with a realistic task tree
    ## The appeal would be ready for distribution by the ACD except there is a blocking mail task
    trait :mail_blocking_distribution do
      ready_for_distribution
      after(:create) do |appeal, _evaluator|
        distribution_task = appeal.tasks.active.detect { |task| task.is_a?(DistributionTask) }
        create(
          :extension_request_mail_task,
          appeal: appeal,
          parent: distribution_task
        )
      end
    end

    ## Appeal with a realistic task tree
    ## The appeal is assigned to a Judge for a decision
    ## Strongly suggest you provide a judge.
    trait :assigned_to_judge do
      ready_for_distribution
      after(:create) do |appeal, evaluator|
        JudgeAssignTask.create!(appeal: appeal,
                                parent: appeal.root_task,
                                assigned_at: evaluator.active_task_assigned_at,
                                assigned_to: evaluator.associated_judge)
        appeal.tasks.where(type: DistributionTask.name).update(status: :completed)
      end
    end

    ## Appeal with a realistic task tree
    ## The appeal is assigned to an Attorney for decision drafting
    ## Strongly suggest you provide a judge and attorney.
    trait :at_attorney_drafting do
      assigned_to_judge
      after(:create) do |appeal, evaluator|
        judge_assign_task = appeal.tasks.where(type: JudgeAssignTask.name).first
        AttorneyTaskCreator.new(
          judge_assign_task,
          appeal: judge_assign_task.appeal,
          assigned_to: evaluator.associated_attorney,
          assigned_by: judge_assign_task.assigned_to
        ).call
      end
    end

    ## Appeal with a realistic task tree
    ## The appeal is assigned to a judge at decision review
    ## Strongly suggest you provide a judge and attorney.
    trait :at_judge_review do
      at_attorney_drafting
      after(:create) do |appeal|
        create(:decision_document, appeal: appeal)
        appeal.tasks.where(type: AttorneyTask.name).first.completed!
      end
    end

    trait :with_straight_vacate_stream do
      after(:create) do |appeal, evaluator|
        mail_task = create(
          :vacate_motion_mail_task,
          appeal: appeal,
          parent: appeal.root_task,
          assigned_to: evaluator.associated_judge
        )
        addr_task = create(
          :judge_address_motion_to_vacate_task,
          appeal: appeal,
          parent: mail_task,
          assigned_to: evaluator.associated_judge
        )
        params = {
          disposition: "granted",
          vacate_type: "straight_vacate",
          instructions: "some instructions",
          assigned_to_id: evaluator.associated_attorney.id
        }
        PostDecisionMotionUpdater.new(addr_task, params).process
      end
    end
  end
end
