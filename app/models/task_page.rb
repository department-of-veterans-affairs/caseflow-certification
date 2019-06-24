# frozen_string_literal: true

class TaskPage
  include ActiveModel::Model

  attr_accessor :assignee

  def tasks_for_tab(tab_name)
    # TODO: Delay the actual execution of these functions until we need their results.
    # Perhaps we could use yield or to_sql
    task_function_for_name = {
      Constants.QUEUE_CONFIG.TRACKING_TASKS_TAB_NAME => tracking_tasks,
      Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME => unassigned_tasks,
      Constants.QUEUE_CONFIG.ASSIGNED_TASKS_TAB_NAME => assigned_tasks,
      Constants.QUEUE_CONFIG.COMPLETED_TASKS_TAB_NAME => recently_completed_tasks
    }

    task_function_for_name[tab_name]
  end

  private

  def tracking_tasks
    TrackVeteranTask.active.where(assigned_to: assignee)
  end

  def unassigned_tasks
    Task.visible_in_queue_table_view.where(assigned_to: assignee).active
  end

  def assigned_tasks
    Task.visible_in_queue_table_view.where(assigned_to: assignee).on_hold
  end

  def recently_completed_tasks
    Task.visible_in_queue_table_view.where(assigned_to: assignee).recently_closed
  end
end
