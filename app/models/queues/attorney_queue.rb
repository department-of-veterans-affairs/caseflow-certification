class AttorneyQueue
  include ActiveModel::Model

  attr_accessor :user

  # This will return tasks that are on hold for the attorney
  def tasks
    CoLocatedAdminAction.where.not(status: "completed").where(assigned_by: user).each do |record|
      record.placed_on_hold_at = record.assigned_at
      record.status = "on_hold"
    end
  end
end