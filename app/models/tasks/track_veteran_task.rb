# frozen_string_literal: true

##
# Task created for appellant representatives to track appeals that have been received by the Board.
# Created either when:
#   - a RootTask is created for an appeal represented by a VSO
#   - the power of attorney changes on an appeal

class TrackVeteranTask < GenericTask
  # Avoid permissions errors outlined in Github ticket #9389 by setting status here.
  before_create :set_in_progress_status

  # Skip unique verification for tracking tasks since multiple VSOs may each have a tracking task and they will be
  # identified as the same organization because they both have the organization type "Vso".
  def verify_org_task_unique; end

  def available_actions(_user)
    []
  end

  def hide_from_queue_table_view
    true
  end

  def hide_from_case_timeline
    true
  end

  def hide_from_task_snapshot
    true
  end

  def self.sync_tracking_tasks(appeal)
    new_task_count = 0
    closed_task_count = 0

    active_tracking_tasks = appeal.tasks.active.where(type: TrackVeteranTask.name)
    cached_vsos = active_tracking_tasks.map(&:assigned_to)
    fresh_vsos = appeal.vsos

    # Create a TrackVeteranTask for each VSO that does not already have one.
    new_vsos = fresh_vsos - cached_vsos
    new_vsos.each do |new_vso|
      TrackVeteranTask.create!(appeal: appeal, parent: appeal.root_task, assigned_to: new_vso)
      new_task_count += 1
    end

    # Close all TrackVeteranTasks for VSOs that are no longer representing the appellant.
    outdated_vsos = cached_vsos - fresh_vsos
    active_tracking_tasks.select { |t| outdated_vsos.include?(t.assigned_to) }.each do |task|
      task.update!(status: Constants.TASK_STATUSES.cancelled)
      closed_task_count += 1
    end

    [new_task_count, closed_task_count]
  end

  private

  def set_in_progress_status
    self.status = Constants.TASK_STATUSES.in_progress
  end
end
