class TasksController < ApplicationController
  before_action :verify_access
  before_action :verify_complete, only: [:complete]
  before_action :verify_assigned_to_current_user, only: [:show, :new, :pdf, :cancel]
  before_action :verify_not_complete, only: [:new]

  class TaskTypeMissingError < StandardError; end

  def index
    @completed_count = Task.completed_today.count
    @to_complete_count = Task.to_complete.count
    render index_template
  end

  def pdf
    decision = task.appeal.decision
    return redirect_to "/404" if decision.nil?
    decision.save_unless_exists!
    send_file(decision.default_path, type: "application/pdf", disposition: "inline")
  end

  def assign
    # Doesn't assign if user has a task of the same type already assigned.
    next_task = current_user_next_task
    return redirect_to "/404" if next_task.nil?
    
    if next_task.user.nil?
      next_task.assign!(current_user)
    end

    redirect_to url_for(action: next_task.initial_action, id: next_task.id)
  end

  def cancel
    task.cancel!
    respond_to do |format|
      format.html { redirect_to(establish_claims_url) }
      format.json { render json: {} }
    end
  end

  private

  def current_user_historical_tasks
    current_user.tasks.completed.newest_first.limit(10)
  end
  helper_method :current_user_historical_tasks

  def next_unassigned_task
    @next_unassigned_task ||= scoped_tasks.unassigned.to_complete.first
  end
  helper_method :next_unassigned_task

  def current_user_next_task
    current_user.tasks.to_complete.where(type: type).first || next_unassigned_task
  end
  helper_method :current_user_next_task

  def scoped_tasks
    Task.where(type: type).oldest_first
  end

  def type
    params[:task_type] || (task && task.type.to_sym)
  end

  def start_text
    type.to_s.titlecase
  end
  helper_method :start_text

  def task_id
    params[:id]
  end

  def task
    @task ||= Task.find(task_id)
  end
  helper_method :task

  def completed_tasks
    @completed_tasks ||= Task.where.not(completed_at: nil).order(created_at: :desc).limit(5)
  end
  helper_method :completed_tasks

  def to_complete_tasks
    @to_complete_tasks ||= Task.to_complete.order(created_at: :desc).limit(5)
  end
  helper_method :to_complete_tasks

  def index_template
    prefix = manager? ? "manager" : "worker"
    "#{prefix}_index"
  end

  def task_roles
    User::TASK_TYPE_TO_ROLES[type] || fail(TaskTypeMissingError)
  end

  def manager?
    current_user.can?(task_roles[:manager])
  end

  def verify_access
    verify_authorized_roles(task_roles[:employee])
  end

  def verify_assigned_to_current_user
    verify_user(task.user)
  end

  def logo_name
    "Dispatch"
  end

  def verify_complete
    return true if task.complete?

    redirect_to url_for(action: task.initial_action, id: task.id)
  end

  def verify_not_complete
    return true unless task.complete?

    redirect_to complete_establish_claim_path(task)
  end
end
