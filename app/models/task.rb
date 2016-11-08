class Task < ActiveRecord::Base
  belongs_to :user
  belongs_to :appeal

  class << self
    def unassigned
      where(user_id: nil)
    end

    def newest_first
      order(created_at: :desc)
    end
  end

  def start_text
    type.titlecase
  end

  def assign(user)
    update_attributes!(
      user: user,
      assigned_at: Time.now.utc
    )
  end

  def assigned?
    assigned_at
  end

  def progress_status
    if completed_at
      "Complete"
    elsif started_at
      "In Progress"
    elsif assigned_at
      "Not Started"
    else
      "Unassigned"
    end
  end

  def complete?
    completed_at
  end

  # completion_status is 0 for success, or non-zero to specify another completed case
  def completed(status)
    update_attributes!(
      completed_at: Time.now.utc,
      completion_status: status
    )
  end

  class << self
    def completed_today
      where(completed_at: DateTime.now.beginning_of_day.utc..DateTime.now.end_of_day.utc)
    end

    def to_complete
      where(completed_at: nil)
    end
  end
end
