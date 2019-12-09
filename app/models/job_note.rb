# frozen_string_literal: true

class JobNote < ApplicationRecord
  belongs_to :user
  belongs_to :job, polymorphic: true

  scope :newest_first, -> { order(created_at: :desc) }

  def ui_hash
    Intake::JobNoteSerializer.new(self).serializable_hash[:data][:attributes]
  end

  def path
    "#{job.path}#job-note-#{id}"
  end
end
