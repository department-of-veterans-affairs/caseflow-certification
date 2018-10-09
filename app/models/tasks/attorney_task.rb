class AttorneyTask < Task
  validates :assigned_by, presence: true
  validates :parent, presence: true, if: :ama?

  validate :assigned_by_role_is_valid
  validate :assigned_to_role_is_valid
  validate :parent_attorney_child_count, on: :create

  def allowed_actions(user)
    return [] if assigned_to != user

    [
      {
        label: "Decision Ready for Review",
        value: "draft_decision/special_issues"
      },
      {
        label: "Add admin action",
        value: "colocated_task"
      }
    ]
  end

  private

  def parent_attorney_child_count
    errors.add(:parent, "has too many children") if parent && parent.children_attorney_tasks.length >= 1
  end

  def assigned_to_role_is_valid
    errors.add(:assigned_to, "has to be an attorney") if assigned_to && !assigned_to.attorney_in_vacols?
  end

  def assigned_by_role_is_valid
    errors.add(:assigned_by, "has to be a judge") if assigned_by && !assigned_by.judge_in_vacols?
  end
end
