# frozen_string_literal: true

class ChangeHearingRequestTypeTask < Task
  validates :parent, presence: true

  def self.label
    "Change hearing request type"
  end

  def self.hide_from_queue_table_view
    true
  end

  def default_instructions
    [COPY::CHANGE_HEARING_REQUEST_TYPE_TASK_DEFAULT_INSTRUCTIONS]
  end

  def available_actions(user)
    if user.can_change_hearing_request_type?
      [
        Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_VIDEO.to_h,
        Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_VIRTUAL.to_h
      ]
    else
      []
    end
  end

  def update_from_params(params, user)
    payload_values = params.delete(:business_payloads)&.dig(:values)

    if payload_values[:changed_request_type].present?
      update_appeal_and_self(payload_values, params)

      [self]
    else
      super(params, user)
    end
  end

  private

  def update_appeal_and_self(payload_values, params)
    multi_transaction do
      appeal.update(changed_request_type: payload_values[:changed_request_type])

      update(params)
    end
  end
end
