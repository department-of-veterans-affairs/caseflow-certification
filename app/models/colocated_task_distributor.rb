class ColocatedTaskDistributor < RoundRobinTaskDistributor
  def initialize(list_of_assignees: Colocated.singleton.non_admins.sort_by(&:id).pluck(:css_id),
                 task_class: Task)
    super
  end

  def next_assignee(_task_class = nil, appeal = nil)
    open_assignee = appeal
      &.tasks
      &.where&.not(status: Constants.TASK_STATUSES.completed)
      &.where(assigned_to_type: "User")
      &.find_by(assigned_to_id: User.where(css_id: list_of_assignees).map(&:id))
      &.assigned_to
    open_assignee || super()
  end
end
