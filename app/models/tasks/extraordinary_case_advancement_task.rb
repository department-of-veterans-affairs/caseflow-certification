# frozen_string_literal: true

##
# Task to record on the appeal that the extraordinary case movement manually assigned the case outside of automatic
#   case distribution

class ExtraordinaryCaseAdvancementTask < GenericTask

  before_create :verify_parent_task_type
  after_create :after_create_function

  private

   def after_create_function
      JudgeAssignTask.create!(appeal: appeal,
                              parent: appeal.root_task,
                              assigned_to: assigned_to,
                              assigned_by: assigned_by,
                              instructions: instructions)
      update!(status: Constants.TASK_STATUSES.completed)
      # For now, we expect the parent to always be the distribution task
      #   so we don't worry about distribution task explicitly
      parent.update!(status: Constants.TASK_STATUSES.completed)
   end

  def verify_parent_task_type
    # For now, we expect the parent to always be the distribution task.
    #   This may change as we add more 'from' scenarios
    if !parent.is_a?(DistributionTask)
      fail(Caseflow::Error::InvalidParentTask,
           message: "Extraordinary Case Advancement must have a Distribution task parent")
    end
  end

end
