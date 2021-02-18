# frozen_string_literal: true

module HearingRequestTypeConcern
  extend ActiveSupport::Concern

  included do
    # Add Paper Trail configuration
    has_paper_trail only: [:changed_request_type], on: [:update]

    validates :changed_request_type,
              inclusion: {
                in: [
                  HearingDay::REQUEST_TYPES[:central],
                  HearingDay::REQUEST_TYPES[:video],
                  HearingDay::REQUEST_TYPES[:virtual]
                ],
                message: "changed request type (%<value>s) is invalid"
              },
              allow_nil: true

    validates :original_request_type,
              inclusion: {
                in: %w[central central_office travel_board video virtual],
                message: "original request type (%<value>s) is invalid"
              },
              allow_nil: true
  end

  # uses the paper_trail version on LegacyAppeal
  def latest_appeal_event
    TaskEvent.new(version: versions.last) if versions.any?
  end

  def original_hearing_request_type
    return original_request_type.to_sym if original_request_type.present?

    # Use the VACOLS value for LegacyAppeals, otherwise use the closest regional office
    original = is_a?(LegacyAppeal) ? hearing_request_type : closest_regional_office
    # Format the request type into a symbol
    format_hearing_request_type(original)
  end

  def readable_original_hearing_request_type
    LegacyAppeal::READABLE_HEARING_REQUEST_TYPES[original_hearing_request_type]
  end

  def remember_original_hearing_request_type
    update!(original_request_type: original_hearing_request_type&.to_s) if original_request_type.blank?
  end

  def current_hearing_request_type
    format_or_formatted_original_request_type(changed_request_type)
  end

  def readable_current_hearing_request_type
    LegacyAppeal::READABLE_HEARING_REQUEST_TYPES[current_hearing_request_type]
  end

  def readable_hearing_request_type_for_task(task_id, version)
    return nil if task_id.nil?

    request_type_index = tasks.where(type: "ChangeHearingRequestTypeTask").order(:id).map(&:id).index(task_id)

    diff = versions[request_type_index].changeset["changed_request_type"]
    versioned_request_type = (version == :prev) ? diff&.first : diff&.last

    # Format the request type into a symbol, or retrieve the original request type
    formatted_request_type = format_or_formatted_original_request_type(versioned_request_type)

    # Return the human readable request type or the symbol of request type
    LegacyAppeal::READABLE_HEARING_REQUEST_TYPES[formatted_request_type]
  end

  private

  def format_or_formatted_original_request_type(request_type)
    if request_type.present?
      format_hearing_request_type(request_type)
    else
      original_hearing_request_type
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def format_hearing_request_type(request_type)
    return nil if request_type.nil?

    case request_type
    when HearingDay::REQUEST_TYPES[:central], :central_office, :central
      is_a?(LegacyAppeal) ? :central_office : :central
    when HearingDay::REQUEST_TYPES[:travel]
      :travel_board
    when :travel_board
      video_hearing_requested ? :video : :travel_board
    when HearingDay::REQUEST_TYPES[:virtual]
      :virtual
    else
      :video
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
end
