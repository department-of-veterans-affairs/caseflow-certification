class ColocatedTaskDistributor < RoundRobinTaskDistributor
  def initialize(list_of_assignees: Colocated.singleton.non_admins.sort_by(&:id).pluck(:css_id),
                 task_type: Task)
    super
  end
end
