# frozen_string_literal: true

class Hearings::Disposition
  attr_reader :hearing_task, :appeal, :hearing
  delegate :reschedule, :reschedule_later, :reschedule_later_with_admin_action, to: :scheduler

  def initialize(hearing_task, scheduler: nil)
    @hearing_task = hearing_task
    @appeal = hearing_task&.appeal
    @hearing = hearing_task&.hearing
    @scheduler = scheduler || Hearings::Schedule.new(appeal, hearing_task: hearing_task)
  end

  def hold!
    update_disposition(Constants.HEARING_DISPOSITION_TYPES.held)

    create_transcription_and_maybe_evidence_submission_window_tasks
  end

  def postpone_and_reschedule!(hearing_params)
    postpone!

    reschedule(hearing_params)
  end

  def postpone_and_reschedule_later!(instructions: nil, admin_action_attributes: nil)
    postpone!

    if admin_action_attributes.nil?
      reschedule_later(instructions: instructions)
    else
      reschedule_later_with_admin_action(
        instructions: instructions,
        admin_action_klass: admin_action_attributes[:admin_action_klass],
        admin_action_instructions: admin_action_attributes[:admin_action_instructions]
      )
    end
  end

  def cancel!
    update_disposition(Constants.HEARING_DISPOSITION_TYPES.cancelled)

    create_evidence_submission_task if appeal.is_a? Appeal
  end

  def no_show!
    update_disposition(Constants.HEARING_DISPOSITION_TYPES.no_show)

    NoShowHearingTask.create_with_hold(hearing_task.disposition_task)
  end

  def admin_changes_needed_after_hearing_date(instructions: nil)
    create_change_hearing_disposition_task(instructions)
  end

  def admin_changes_needed_on_previous_hearing(instructions: nil)
    previous_hearing_task = hearing_task.most_recent_closed_hearing_task_on_appeal

    if previous_hearing_task&.hearing&.disposition.blank?
      fail Caseflow::Error::ActionForbiddenError, message: COPY::REQUEST_HEARING_DISPOSITION_CHANGE_FORBIDDEN_ERROR
    end

    # cancel the old HearingTask and create a new one associated with the same hearing
    new_hearing_task = hearing_task.cancel_and_recreate
    HearingTaskAssociation.create!(hearing: previous_hearing_task.hearing, hearing_task: new_hearing_task)

    # create a ChangeHearingDispositionTask on the new HearingTask
    ChangeHearingDispositionTask.create!(
      appeal: new_hearing_task.appeal,
      parent: new_hearing_task,
      instructions: instructions.present? ? [instructions] : nil
    )
  end

  private

  def postpone!
    update_disposition(Constants.HEARING_DISPOSITION_TYPES.postponed)
  end

  def update_disposition(disposition)
    if hearing.is_a?(LegacyHearing)
      hearing.update_caseflow_and_vacols(disposition: disposition)
    else
      hearing.update(disposition: disposition)
    end
  end

  def create_evidence_submission_task
    EvidenceSubmissionWindowTask.create!(
      appeal: appeal,
      parent: hearing_task.parent,
      assigned_to: MailTeam.singleton
    )
  end

  def create_transcription_and_maybe_evidence_submission_window_tasks
    TranscriptionTask.create!(appeal: appeal, parent: hearing_task, assigned_to: TranscriptionTeam.singleton)
    unless hearing&.evidence_window_waived
      create_evidence_submission_task
    end
  end

  def create_change_hearing_disposition_task(instructions = nil)
    task_names = [AssignHearingDispositionTask.name, ChangeHearingDispositionTask.name]
    active_disposition_tasks = hearing_task.children.open.where(type: task_names).to_a

    ChangeHearingDispositionTask.create!(
      appeal: appeal,
      parent: hearing_task,
      instructions: instructions.present? ? [instructions] : nil
    )
    active_disposition_tasks.each { |task| task.update!(status: Constants.TASK_STATUSES.completed) }
  end

  def legacy_withdrawal_location
    if appeal.representatives.empty?
      LegacyAppeal::LOCATION_CODES[:case_storage]
    else
      LegacyAppeal::LOCATION_CODES[:service_organization]
    end
  end
end
