class RootTask < GenericTask
  after_initialize :set_assignee

  def set_assignee
    self.assigned_to = Bva.singleton
  end

  def when_child_task_completed; end

  def available_actions(user)
    return [Constants.TASK_ACTIONS.CREATE_MAIL_TASK.to_h] if MailTeam.singleton.user_has_access?(user) && ama?
    return [Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h] if can_create_schedule_hearings_task?(user)

    []
  end

  def can_create_schedule_hearings_task?(user)
    HearingsManagement.singleton.user_has_access?(user) &&
      !completed? &&
      legacy? &&
      children.where(type: ScheduleHearingTask.name).where.not(status: Constants.TASK_STATUSES.completed).empty?
  end

  def actions_available?(_user)
    true
  end

  class << self
    def create_root_and_sub_tasks!(appeal)
      root_task = create!(appeal: appeal)
      if FeatureToggle.enabled?(:ama_auto_case_distribution)
        create_subtasks!(appeal, root_task)
      else
        create_vso_subtask!(appeal, root_task)
      end
    end

    private

    def create_vso_subtask!(appeal, parent)
      appeal.vsos.map do |vso_organization|
        InformalHearingPresentationTask.create!(
          appeal: appeal,
          parent: parent,
          assigned_to: vso_organization
        )
      end
    end

    def create_evidence_submission_task!(appeal, parent)
      EvidenceSubmissionWindowTask.create!(
        appeal: appeal,
        parent: parent,
        assigned_to: MailTeam.singleton
      )
    end

    def create_distribution_task!(appeal, parent)
      DistributionTask.create!(
        appeal: appeal,
        parent: parent,
        assigned_to: Bva.singleton
      )
    end

    def create_subtasks!(appeal, parent)
      transaction do
        distribution_task = create_distribution_task!(appeal, parent)
        current_parent = distribution_task

        if appeal.needs_ihp?
          vso_tasks = create_vso_subtask!(appeal, current_parent)
          # TODO: when or if there are more than one vso, vso tasks
          # should expire at the same time. which one should be the
          # blocking parent of evidence submission tasks?
          current_parent = vso_tasks.first
        end

        create_evidence_submission_task!(appeal, current_parent) if appeal.evidence_submission_docket?
      end
    end
  end
end
