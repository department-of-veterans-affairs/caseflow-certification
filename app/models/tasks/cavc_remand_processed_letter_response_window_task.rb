# frozen_string_literal: true

##
# Task to indicate that Litigation Support is awaiting a response from the appellant,
# after sending the CAVC-remand-processed letter to an appellant (SendCavcRemandProcessedLetterTask).
# This task is for CAVC Remand appeal streams.
# The appeal is put on hold for 90 days, with the option of ending the hold early.
# After 90 days, the task comes off hold and show up in the CavcLitigationSupport team's unassigned tab
# to be assigned and acted upon.
# Expected parent: CavcTask
# Expected assigned_to.type: CavcLitigationSupport

class CavcRemandProcessedLetterResponseWindowTask < Task
  validates :parent, presence: true, parentTask: { task_type: CavcTask }, on: :create

  before_validation :set_assignee

  def self.create_with_hold(parent_task)
    multi_transaction do
      create!(parent: parent_task, appeal: parent_task.appeal).tap do |window_task|
        TimedHoldTask.create_from_parent(
          window_task,
          days_on_hold: 90,
          instructions: ["This case is on hold for 90 days to allow the appellant to respond."]
        )
    end
  rescue ActiveRecord::RecordInvalid
    errors.add(:parent, "should be a CavcTask")
  end
end

  USER_ACTIONS = [
    Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h
  ].freeze

  def self.label
    COPY::CAVC_REMAND_PROCESSED_LETTER_RESP_WINDOW_TASK_LABEL
  end

  def default_instructions
    [COPY::CAVC_TASK_DEFAULT_INSTRUCTIONS]
  end

  def available_actions(_user)
    USER_ACTIONS
  end

  private

  def set_assignee
    self.assigned_to = CavcLitigationSupport.singleton if assigned_to.nil?
  end
end
