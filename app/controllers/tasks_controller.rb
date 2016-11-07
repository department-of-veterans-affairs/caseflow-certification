class TasksController < ApplicationController
  def index
    @completed_count = Task.completed_today.count
    @to_complete_count = Task.to_complete.count
  end

  def show
    @task = Task.find(task_id)
  end

  private

  def department
    params[:department]
  end

  def task_id
    params[:id]
  end

  def completed_tasks
    @completed_tasks ||= Task.where.not(completed_at: nil).order(created_at: :desc).limit(5)
  end
  helper_method :completed_tasks
  
  def to_complete_tasks
    @to_complete_tasks ||= Task.to_complete.order(created_at: :desc).limit(5)
  end
  helper_method :to_complete_tasks
end
