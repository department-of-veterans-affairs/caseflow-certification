# frozen_string_literal: true

class HearingRenderer
  RENDERABLE_CLASSNAMES = %w[
    Veteran
    Appeal
    LegacyAppeal
    Hearing
    LegacyHearing
    HearingTask
    VirtualHearing
  ].freeze

  class << self
    def test_veteran_with_ama
      ama_virtual_hearing = VirtualHearing.not_cancelled.where(hearing_type: Hearing.name).last
      veteran_with_ama_hearing = ama_virtual_hearing.hearing.appeal.veteran
      puts render(veteran_with_ama_hearing)
    end

    def test_veteran_with_ama_with_pii
      ama_virtual_hearing = VirtualHearing.not_cancelled.where(hearing_type: Hearing.name).last
      veteran_with_ama_hearing = ama_virtual_hearing.hearing.appeal.veteran
      puts render(veteran_with_ama_hearing, show_pii: true)
    end

    def test_veteran_with_legacy
      legacy_virtual_hearing = VirtualHearing.not_cancelled.where(hearing_type: LegacyHearing.name).last
      veteran_with_legacy_hearing = legacy_virtual_hearing.hearing.appeal.veteran
      puts render(veteran_with_legacy_hearing)
    end

    def test_veteran_with_legacy_with_pii
      legacy_virtual_hearing = VirtualHearing.not_cancelled.where(hearing_type: LegacyHearing.name).last
      veteran_with_legacy_hearing = legacy_virtual_hearing.hearing.appeal.veteran
      puts render(veteran_with_legacy_hearing, show_pii: true)
    end

    def test_breadcrumbs
      ama_virtual_hearing = VirtualHearing.not_cancelled.where(hearing_type: Hearing.name).last
      puts render(ama_virtual_hearing.hearing)
    end

    def render(obj, show_pii: false)
      renderer = HearingRenderer.new(show_pii: show_pii)
      TTY::Tree.new(renderer.structure(obj, include_breadcrumbs: true)).render
    end

    def renderable_classes
      RENDERABLE_CLASSNAMES.map(&:constantize)
    end

    def prefix(obj)
      klass = renderable_classes.find { |k| obj.is_a?(k) }
      klass&.name&.underscore
    end
  end

  attr_reader :show_pii

  def initialize(show_pii: false)
    @show_pii = show_pii
  end

  def structure(obj, include_breadcrumbs: false)
    return if obj.nil?

    children = try("#{self.class.prefix(obj)}_children", obj)&.compact || []
    if include_breadcrumbs
      context = calculate_breadcrumbs(obj)
      children << { "breadcrumbs:": context } if context.present?
    end
    { "#{label(obj)}": children }
  end

  def label(obj)
    return "nil" if obj.nil?

    result = "#{obj.class.name} #{obj.id}"
    details = try("#{self.class.prefix(obj)}_details", obj)&.compact
    result += " (#{details.join(', ')})" if details.present?
    result
  end

  def calculate_breadcrumbs(obj)
    context = try("#{self.class.prefix(obj)}_context", obj)
    return [] if context.blank?

    [label(context), calculate_breadcrumbs(context)].flatten
  end

  def veteran_details(vet)
    details = []
    details += [vet.name, "FN: #{vet.file_number}"] if show_pii
    details << "PID: #{vet.participant_id}"
    details
  end

  def readable_date(date, include_time = true)
    if include_time
      date.strftime("%m-%d-%Y %I:%M%p %Z")
    else
      date.strftime("%m-%d-%Y")
    end
  end

  def veteran_children(vet)
    appeals = Appeal.where(veteran_file_number: vet.file_number)
    appeals.sort_by { |appeal| appeal.receipt_date || Time.zone.today }
    legacy_appeals = LegacyAppeal.fetch_appeals_by_file_number(vet.file_number)
    legacy_appeals.sort_by { |la| la.created_at || Time.zone.today }

    children = []
    children += legacy_appeals.map { |legacy_appeal| structure(legacy_appeal) }
    children += appeals.map { |appeal| structure(appeal) }
    children
  end

  def get_appeal_type_conversions(appeal)
    unformatted_versions = appeal.versions
    versions = unformatted_versions.map do |v|
      change = v.changeset["changed_hearing_request_type"] ||
               v.changeset["changed_request_type"]
      {
        "from_type" => print_nil(Hearing::HEARING_TYPES[change[0]&.to_sym]),
        "to_type" => Hearing::HEARING_TYPES[change[1]&.to_sym],
        "converted_by" => User.find(v.whodunnit).css_id,
        "converted_at" => readable_date(v.created_at)
      }
    end

    versions
  end

  def format_original_and_current_type(appeal)
    original = print_nil(appeal.readable_original_hearing_request_type)
    current = print_nil(appeal.readable_current_hearing_request_type)
    if original == current && appeal.versions.count == 0
      ["Current type: #{current}"]
    else
      ["Original Type: #{original}, current type: #{current}"]
    end
  end

  def format_conversions(type_conversions)
    type_conversions.map do |tc|
      "Converted to #{tc['to_type']} from #{tc['from_type']} by #{tc['converted_by']} at #{tc['converted_at']}"
    end
  end

  def add_original_type(original_type, type_conversions)
    first_conversion = type_conversions[0]
    first_conversion["from_type"] = original_type
    type_conversions[0] = first_conversion

    type_conversions
  end

  def get_appeal_history(appeal)
    if appeal.versions.empty?
      format_original_and_current_type(appeal)
    else
      type_conversions = get_appeal_type_conversions(appeal)
      type_conversions_with_original_type = add_original_type(
        appeal.readable_original_hearing_request_type,
        type_conversions
      )
      text = format_original_and_current_type(appeal)
      text += format_conversions(type_conversions_with_original_type)
      text
    end
  end

  def get_unscheduled_hearings(appeal)
    regional_office = appeal.closest_regional_office
    ro_label = regional_office.nil? ? COPY::UNKNOWN_REGIONAL_OFFICE : get_ro_label(regional_office)

    open_schedule_hearing_tasks = appeal.tasks.open.of_type(:ScheduleHearingTask)
    return "" if open_schedule_hearing_tasks.nil?

    unscheduled_hearings = open_schedule_hearing_tasks.map do |sh_task|
      unscheduled_hearing_label = "Unscheduled Hearing (SCH Task ID: #{sh_task.id}, RO queue: #{ro_label})"
      unscheduled_note = show_pii ? sh_task.parent&.instructions : "Show PII to see notes"

      { unscheduled_hearing_label => ["Notes: #{unscheduled_note}"] }
    end

    unscheduled_hearings
  end

  def shared_appeal_children(appeal)
    children = []
    if appeal.appellant_is_not_veteran
      children << "Appellant is not veteran - #{appeal&.appellant_relationship}"
    end

    children += appeal.hearings.map { |hearing| structure(hearing) }
    children += get_unscheduled_hearings(appeal)

    children << {
      "Appeal History": get_appeal_history(appeal)
    }
    children
  end

  def legacy_appeal_details(legacy_appeal)
    ["VACOLS ID: #{legacy_appeal.vacols_id}"]
  end

  def legacy_appeal_children(legacy_appeal)
    shared_appeal_children(legacy_appeal)
  end

  def legacy_appeal_context(legacy_appeal)
    legacy_appeal.veteran
  end

  def appeal_details(appeal)
    ["UUID: #{appeal.uuid}"]
  end

  def appeal_children(appeal)
    shared_appeal_children(appeal)
  end

  def appeal_context(appeal)
    appeal.veteran
  end

  def scheduled_for(hearing)
    ro_time = hearing.scheduled_for.in_time_zone(hearing.regional_office_timezone)
    if ro_time != hearing.scheduled_for
      "Scheduled for: #{readable_date(hearing.scheduled_for)} / #{ro_time.strftime('%I:%M%p %Z')}(RO time)"
    end

    "Scheduled for: #{readable_date(hearing.scheduled_for)}"
  end

  def print_nil(obj)
    obj.presence || "none"
  end

  def get_ro_label(regional_office, request_type = false)
    regional_office_city_info ||= RegionalOffice::CITIES[regional_office]
    city_state_string = if regional_office_city_info.nil?
                          ""
                        else
                          "#{regional_office_city_info[:city]} #{regional_office_city_info[:state]}"
                        end

    formatted_text = regional_office.nil? ? "no ro, " : "#{regional_office} - #{city_state_string}"
    formatted_text += request_type ? ", #{Hearing::HEARING_TYPES[request_type&.to_sym]}" : ""

    formatted_text
  end

  def format_hearing_day_label(hearing_day)
    formatted_text = "HearingDay #{hearing_day.id}"
    formatted_text += " (#{get_ro_label(hearing_day.regional_office, hearing_day.request_type)}) "
    formatted_text
  end

  def format_hearing_label(hearing)
    hearing_type = print_nil(hearing.readable_request_type)
    disposition = hearing.disposition.nil? ? "no disposition" : hearing.disposition
    coordinator = hearing.bva_poc.nil? ? "no coordinator" : hearing.bva_poc

    "#{hearing_type}, #{disposition}, #{coordinator}"
  end

  def shared_hearing_children(hearing)
    children = []
    children << "Notes: #{print_nil(hearing.notes)}" if show_pii
    children << scheduled_for(hearing)
    children << format_hearing_label(hearing)
    children << format_hearing_day_label(hearing.hearing_day)
    virtual_hearings = VirtualHearing.where(hearing_id: hearing.id, hearing_type: hearing.class.name)
    children += virtual_hearings.map { |vh| structure(vh) }
    children << {
      "Email events": hearing.email_events.map do |ev|
        "#{ev.recipient_role}, #{ev.email_type}, "\
          "#{readable_date(ev.sent_at, false)}, #{ev.external_message_id}"
      end
    }
    children << structure(hearing.hearing_task_association.hearing_task)
  end

  def legacy_hearing_children(hearing)
    shared_hearing_children(hearing)
  end

  def legacy_hearing_details(hearing)
    ["VACOLS ID: #{hearing.vacols_id}"]
  end

  def legacy_hearing_context(hearing)
    hearing.appeal
  end

  def hearing_children(hearing)
    shared_hearing_children(hearing)
  end

  def hearing_details(hearing)
    ["UUID: #{hearing.uuid}"]
  end

  def hearing_context(hearing)
    hearing.appeal
  end

  def hearing_task_children(hearing_task)
    children = []
    children << "instr: #{print_nil(hearing_task.instructions)}" if show_pii
    children += hearing_task.children.map do |ct|
      if ct.is_a?(ScheduleHearingTask) || ct.is_a?(AssignHearingDispositionTask)
        "#{ct.class.name} #{ct.id} (#{ct.status}, ca: #{readable_date(ct.created_at)})"
      end
    end

    children
  end

  def hearing_task_details(hearing_task)
    ["#{hearing_task.status}, ca: #{readable_date(hearing_task.created_at)}"]
  end

  def hearing_task_context(hearing_task)
    hearing_task.appeal
  end

  def email_sent(flag)
    flag ? "email sent" : "email not sent"
  end

  def virtual_hearing_children(virtual_hearing)
    children = []
    recipients = []

    if virtual_hearing.appellant_email.present?
      recipients << "appellant - #{email_sent(virtual_hearing.appellant_email_sent)}"
    end

    if virtual_hearing.representative_email.present?
      recipients << ", rep - #{email_sent(virtual_hearing.representative_email_sent)}"
    end

    if virtual_hearing.judge_email.present?
      recipients << ", judge - #{email_sent(virtual_hearing.judge_email_sent)}" 
    end

    children << recipients.join
    children
  end

  def virtual_hearing_details(virtual_hearing)
    ["#{virtual_hearing.status}, ca: #{readable_date(virtual_hearing.created_at)}, "\
      "#{virtual_hearing.created_by&.css_id}"]
  end

  def virtual_hearing_context(virtual_hearing)
    virtual_hearing.hearing
  end
end
