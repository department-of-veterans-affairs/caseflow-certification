# frozen_string_literal: true

class PostDecisionMotionsController < ApplicationController
  before_action :verify_task_access, only: [:create, :return_to_lit_support, :return_to_judge]

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def create
    motion_updater = PostDecisionMotionUpdater.new(task, motion_params)
    motion_updater.process

    if motion_updater.errors.present?
      render json: { errors: [detail: motion_updater.errors.full_messages.join(", ")] }, status: :bad_request
      return
    end
    render json: {}
  end

  def return_to_lit_support
    mail_task = task.parent
    mail_task.update_with_instructions(instructions: params[:instructions]) if params[:instructions].present?

    task.update!(status: Constants.TASK_STATUSES.cancelled)
    appeal_tasks = mail_task.appeal.reload.tasks
    render json: { tasks: ::WorkQueue::TaskSerializer.new(appeal_tasks, is_collection: true) }
  end

  def return_to_judge
    new_task = PostDecisionMotionDeleter.new(task, params[:instructions]).process
    render json: {
      task: ::WorkQueue::TaskSerializer.new(new_task)
    }
  end

  private

  def verify_task_access
    if task.assigned_to != current_user
      fail Caseflow::Error::ActionForbiddenError, message: "Only task assignee can perform this action"
    end
  end

  def task
    @task ||= Task.find(motion_params[:task_id])
  end

  def motion_params
    params.permit(:disposition, :task_id, :vacate_type, :instructions, :assigned_to_id, vacated_decision_issue_ids: [])
  end
end
