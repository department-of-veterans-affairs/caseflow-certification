# frozen_string_literal: true

class AttorneySerializer
  include FastJsonapi::ObjectSerializer
  attribute :id
  attribute :css_id
  attribute :full_name
  attribute :active_task_count do |object|
    object.tasks.active.size
  end
end
