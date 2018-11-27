class GenericTask < Task
  before_create :verify_org_task_unique

  # Use the existence of an organization-level task to prevent duplicates since there should only ever be one org-level
  # task active at a time for a single appeal.
  def verify_org_task_unique
    if Task.where(type: type, assigned_to: assigned_to, appeal: appeal)
        .where.not(status: Constants.TASK_STATUSES.completed).any? &&
       assigned_to.is_a?(Organization)
      fail(
        Caseflow::Error::DuplicateOrgTask,
        appeal_id: appeal.id,
        task_type: self.class.name,
        assignee_type: assigned_to.class.name
      )
    end
  end

  # rubocop:disable Metrics/MethodLength
  def available_actions(user)
    return [] unless user

    if assigned_to == user
      return [
        Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
        Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.MARK_COMPLETE.to_h
      ]
    end

    if task_is_assigned_to_user_within_organiztaion?(user)
      return [
        Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h
      ]
    end

    if task_is_assigned_to_users_organization?(user)
      return [
        Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
        Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.MARK_COMPLETE.to_h
      ]
    end

    []
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def update_from_params(params, current_user)
    verify_user_access!(current_user)
    params = modify_update_params(params)

    return reassign(params[:reassign], current_user) if params[:reassign]

    update_status(params.delete(:status))
    update!(params)

    [self]
  end

  def reassign(reassign_params, current_user)
    reassign_params[:instructions] = [instructions, reassign_params[:instructions]].flatten
    sibling = self.class.create_child_task(parent, current_user, reassign_params)
    mark_as_complete!

    children_to_update = children.reject { |t| t.status == Constants.TASK_STATUSES.completed }
    children_to_update.each { |t| t.update!(parent_id: sibling.id) }

    [sibling, self, children_to_update].flatten
  end

  def can_be_accessed_by_user?(user)
    !available_actions(user).empty?
  end

  def update_status(status)
    return unless status

    case status
    when Constants.TASK_STATUSES.completed
      mark_as_complete!
    else
      update!(status: status)
    end
  end

  private

  def task_is_assigned_to_user_within_organiztaion?(user)
    parent &&
      parent.assigned_to.is_a?(Organization) &&
      assigned_to.is_a?(User) &&
      parent.assigned_to.user_has_access?(user)
  end

  def task_is_assigned_to_users_organization?(user)
    assigned_to.is_a?(Organization) && assigned_to.user_has_access?(user)
  end

  class << self
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def create_from_params(params, user)
      parent = Task.find(params[:parent_id]) if params[:parent_id]
      fail Caseflow::Error::ChildTaskAssignedToSameUser if parent && parent.assigned_to_id == params[:assigned_to_id] &&
                                                           parent.assigned_to_type == params[:assigned_to_type]

      parent.verify_user_access!(user) if parent

      params = modify_params(params)
      child = create_child_task(parent, user, params)
      parent.update_status(params[:status]) if parent && parent.is_a?(GenericTask)
      child
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity

    def create_child_task(parent, user, params)
      # Create an assignee from the input arguments so we throw an error if the assignee does not exist.
      assignee = params[:assigned_to] || Object.const_get(params[:assigned_to_type]).find(params[:assigned_to_id])

      parent.update_status(Constants.TASK_STATUSES.on_hold) if parent && parent.is_a?(GenericTask)

      Task.create!(
        type: name,
        appeal: parent.try(:appeal) || params[:appeal],
        assigned_by_id: child_assigned_by_id(parent, user),
        parent_id: parent.try(:id),
        assigned_to: assignee,
        action: params[:action],
        instructions: params[:instructions]
      )
    end

    def child_assigned_by_id(parent, user)
      return user.id if user
      return parent.assigned_to_id if parent && parent.assigned_to_type == User.name
    end
  end
end
