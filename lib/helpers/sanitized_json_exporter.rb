# frozen_string_literal: true

class SanitizedJsonExporter
  attr_accessor :value_mapping
  attr_accessor :records_hash

  # :reek:BooleanParameter
  def initialize(*initial_appeals, sanitize: true)
    @sanitize = sanitize
    @value_mapping = {}
    @records_hash = { "metadata" => { "exported_at": Time.zone.now } }

    records_to_export(initial_appeals).each do |clazz, records|
      # puts "Exporting #{clazz.table_name}"
      @records_hash[clazz.table_name] = sanitize_records(records)
    end
  end

  def records_to_export(initial_appeals)
    associated_appeals = initial_appeals.map { |appeal| appeals_associated_with(appeal) }.flatten.uniq.compact
    appeals = (initial_appeals + associated_appeals).uniq
    tasks = appeals.map(&:tasks).flatten.sort_by(&:id).extend(TaskAssignment)
    cavc_remands = appeals.map(&:cavc_remand).compact
    hearings = tasks.with_type("HearingTask").map(&:hearing).uniq.compact
    hearing_days = hearings.map(&:hearing_day).uniq.compact

    users = tasks.map(&:assigned_by).compact +
            tasks.assigned_to_user.map(&:assigned_to) +
            cavc_remands.map { |cavc_remand| [cavc_remand.created_by, cavc_remand.updated_by] }.flatten.uniq.compact +
            appeals.map(&:intake).compact.map(&:user).uniq.compact +
            hearing_days.map { |hd| [hd.created_by, hd.updated_by, hd.judge] }.flatten.uniq.compact +
            hearings.map { |h| [h.created_by, h.updated_by, h.judge] }.flatten.uniq.compact +
            hearings.map(&:virtual_hearing).uniq.compact
              .map { |vh| [vh.created_by, vh.updated_by] }.flatten.uniq.compact

    request_issues = appeals.map(&:request_issues).flatten
    {
      Appeal => appeals,
      AppealIntake => appeals.map(&:intake),
      Veteran => appeals.map(&:veteran),
      Claimant => appeals.map(&:claimants).flatten,
      Task => tasks,
      TaskTimer => TaskTimer.where(task_id: tasks.map(&:id)),
      User => users,
      Organization => tasks.assigned_to_org.map(&:assigned_to) + users.map(&:organizations).flatten.uniq,
      OrganizationsUser => OrganizationsUser.where(user: users),
      CavcRemand => cavc_remands,
      DecisionIssue => appeals.map(&:decision_issues).flatten,
      RequestIssue => request_issues,
      RequestDecisionIssue => RequestDecisionIssue.where(request_issue: request_issues),
      Hearing => hearings,
      HearingTaskAssociation => HearingTaskAssociation.where(hearing: hearings),
      HearingDay => hearing_days,
      VirtualHearing => hearings.map(&:virtual_hearing).uniq.compact
    }
  end
  # rubocop:enable

  # To-do: load this from a file or automatically determine fields to sanitize
  SANITIZE_FIELDS = {
    Appeal => %w[veteran_file_number],
    AppealIntake => %w[veteran_file_number],
    Veteran => %w[first_name last_name middle_name file_number ssn],
    User => %w[full_name email css_id],
    Task => %w[instructions],
    # cavc_judge_full_name is selected from Constants::CAVC_JUDGE_FULL_NAMES; no need to sanitize
    CavcRemand => %w[instructions],
    Organization => %w[],
    Claimant => %w[],
    TaskTimer => %w[],
    OrganizationsUser => %w[],
    RequestDecisionIssue => %w[],
    RequestIssue => ["notes", /_(notes|text|description)/],
    DecisionIssue => %w[description decision_text],
    HearingTaskAssociation => %w[],
    Hearing => %w[notes military_service summary bva_poc representative_name witness],
    HearingDay => %w[bva_poc notes],
    VirtualHearing => %w[alias guest_pin host_pin guest_pin_long host_pin_long representative_email
                         judge_email alias_with_host appellant_email host_hearing_link guest_hearing_link]
  }.freeze

  # To-do: load this from a file or automatically determine fields to sanitize
  # https://stackoverflow.com/questions/13355549/rails-activerecord-detect-if-a-column-is-an-association-or-not
  OFFSET_ID_FIELDS = {
    Task => %w[appeal_id parent_id],
    Claimant => %w[decision_review_id],
    TaskTimer => %w[task_id],
    AppealIntake => %w[detail_id],
    CavcRemand => %w[source_appeal_id remand_appeal_id decision_issue_ids],
    OrganizationsUser => %w[user_id organization_id],
    DecisionIssue => %w[decision_review_id],
    RequestIssue => %w[decision_review_id contested_decision_issue_id],
    RequestDecisionIssue => %w[request_issue_id decision_issue_id],
    Hearing => %w[appeal_id hearing_day_id],
    HearingTaskAssociation => %w[hearing_id hearing_task_id],
    VirtualHearing => %w[hearing_id]
  }.freeze

  REASSOCIATE_FIELDS = {
    "User" => {
      Task => %w[assigned_by_id],
      AppealIntake => %w[user_id],
      CavcRemand => %w[created_by_id updated_by_id],
      Hearing => %w[created_by_id updated_by_id],
      HearingDay => %w[created_by_id updated_by_id judge_id],
      VirtualHearing => %w[created_by_id updated_by_id]
    },
    :type => {
      Task => %w[assigned_to_id]
    }
  }.freeze

  def appeals_associated_with(appeal)
    appeal.cavc_remand&.source_appeal
    # To-do: include other source appeals, e.g., those with the same docket number
  end

  def save(filename, purpose: nil)
    @records_hash["metadata"]["purpose"] = purpose if purpose
    File.open(filename.to_s, "w") { |file| file.puts file_contents }
  end

  def file_contents
    JSON.pretty_generate(@records_hash)
  end

  # temporary method; delete for final PR
  # :reek:BooleanParameter
  def self.record_to_hash(record, call_attributes: true)
    return record.attributes if call_attributes

    # Alternative implementation
    json_string = record.to_json(methods: :type)
    JSON.parse(json_string)
  end

  private

  module TaskAssignment
    def assigned_to_user
      select { |task| task.assigned_to_type == "User" }
    end

    def assigned_to_org
      select { |task| task.assigned_to_type == "Organization" }
    end

    def with_type(task_type)
      select { |task| task.type == task_type }
    end
  end

  def sanitize_records(records)
    # keep records in order so that comparisons can be done after import
    records.uniq.compact.sort_by(&:id).map { |record| sanitize(record) }
  end

  KNOWN_CLASSES = SANITIZE_FIELDS.keys.freeze
  SANITIZE_TABLE_FIELDS = SANITIZE_FIELDS.transform_keys(&:table_name).freeze

  def sanitize(record)
    obj_hash = self.class.record_to_hash(record)
    return obj_hash unless @sanitize

    case record
    when User
      # User#attributes includes `display_name`; don't need it when importing so leave it out
      obj_hash.delete(:display_name)
    end

    if KNOWN_CLASSES.any? { |klass| record.is_a?(klass) }
      # Use table_name to handle subclasses/STI: e.g., a HearingTask record maps to table "tasks"
      SANITIZE_TABLE_FIELDS[record.class.table_name].each do |field_name|
        if field_name.is_a?(Regexp)
          obj_hash.keys.select { |k| k.match?(field_name) }.each do |key|
            find_or_create_mapped_value_for(obj_hash, key, obj_class: record.class)
          end
        elsif field_name.is_a?(String)
          find_or_create_mapped_value_for(obj_hash, field_name, obj_class: record.class)
        elsif obj_hash.key?(field_name)
          fail "#{record.class} record doesn't have field_name '#{field_name}': #{obj_hash}"
        else
          fail "Expecting string or regex for the #{record.class}'s field name: #{field_name}"
        end
      end
      return obj_hash
    end

    fail "Unsupported object type: #{record.class.name}"
  end
  # rubocop:enable

  def find_or_create_mapped_value_for(obj_hash, field_name, **kwargs)
    return unless obj_hash[field_name]

    # Loop to ensure hash @value_mapping has a different value for each distinct key
    10.times do
      obj_hash[field_name] = find_or_create_mapped_value(obj_hash[field_name], field_name, **kwargs)
      break if @value_mapping.values.uniq.size == @value_mapping.size

      puts "Value '#{obj_hash[field_name]}' for field #{field_name} is already used; trying again"
    end
    obj_hash[field_name]
  end

  def find_or_create_mapped_value(orig_value, field_name = nil, **kwargs)
    mapped_value = @value_mapping.fetch(orig_value) do
      if orig_value.is_a?(Array)
        value_and_transforms = orig_value.map { |val| map_value(val, field_name, **kwargs) }
        value_and_transforms.map(&:first)
      else
        map_value(orig_value, field_name, **kwargs).first
      end
    end
    mapped_value || fail("Don't know how to map value '#{orig_value}' for field '#{field_name}'")
  end

  # fields whose mapped value should not be saved to the @value_mapping hash,
  # e.g., due to distinct orig_values mapping to the same new_value
  MAPPED_VALUES_IGNORED_FIELDS = %w[first_name middle_name last_name].freeze
  MAPPED_VALUES_IGNORED_TRANSFORMS = [:obfuscate_sentence, :similar_date].freeze

  def map_value(orig_value, field_name, obj_class: nil, transform_method: nil)
    # find the first of TRANSFORM_METHODS that returns a non-nil value
    transform_method ||= TRANSFORM_METHODS.find { |method| self.class.send(method, field_name, orig_value) }
    fail "For #{obj_class.name} field '#{field_name}' with value '#{orig_value}' of class #{orig_value.class}, could not find a transform_method" unless transform_method

    new_value = self.class.send(transform_method, field_name, orig_value)

    # Don't save the value_mapping for certain transforms
    if !(MAPPED_VALUES_IGNORED_TRANSFORMS.include?(transform_method) || MAPPED_VALUES_IGNORED_FIELDS.include?(field_name))
      @value_mapping[orig_value] = new_value
    end
    [new_value, transform_method]
  end

  # To-do: generate the automatically
  TRANSFORM_METHODS = [:mixup_css_id, :random_person_name, :invalid_ssn, :random_email, :obfuscate_sentence, :similar_date, :random_pin].freeze

  class << self
    # :reek:RepeatedConditionals
    def random_email(field_name, field_value)
      case field_name
      when "email_address", /email$/
        Faker::Internet.email
      else
        case field_value
        when /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
          Faker::Internet.email
        end
      end
    end

    def invalid_ssn(field_name, field_value, fake_ssn_prefix: "000")
      # Instead of using Faker::IDNumber.invalid, make the SSN obviously fake by starting with fake_ssn_prefix
      case field_name
      when "ssn", "file_number", "veteran_file_number"
        fake_ssn_prefix + Faker::Number.number(digits: 6).to_s
      else
        case field_value
        when /^\d{9}$/
          fake_ssn_prefix + Faker::Number.number(digits: 6).to_s
        when /^\d{3}-\d{2}-\d{4}$/
          [fake_ssn_prefix, Faker::Number.number(digits: 2), Faker::Number.number(digits: 4)].join("-")
        end
      end
    end

    def random_person_name(field_name, _field_value)
      case field_name
      when "full_name", "representative_name"
        Faker::Name.name
      when "bva_poc"
        Faker::Name.name.upcase
      when "last_name"
        Faker::Name.last_name
      when "middle_name"
        Faker::Name.initials(number: 1)
      when "first_name"
        Faker::Name.first_name
      when "witness"
        witnesses = []
        rand(1..2).times do
          relationship = ["spouse", "daughter", "son", "wife", "husband",
                          "observer", "friend", "girlfriend", "brother-in-law",
                          "witness", "cousin", "stepson", "bva attorney",
                          "conservator", "daughter-in-law", "rep", "father",
                          "bva counsel"].sample
          witnesses << "#{Faker::Name.name} (#{relationship})"
        end
        witnesses.join(", ")
      when /_name$/
        Faker::Name.first_name
      end
    end

    def similar_date(field_name, field_value)
      case field_name
      when "date_of_birth"
        case field_value
        when Date
          Faker::Date.between_except(from: field_value - 1.year, to: field_value, excepted: field_value)
        when /^\d{4}-\d{2}-\d{2}$/
          Faker::Date.between_except(from: Date.parse(field_value) - 1.year, to: field_value, excepted: field_value).to_json
        end
      end
    end

    def random_pin(field_name, field_value)
      case field_name
      when /_pin$/, /_pin_/
        if field_value.is_a?(String)
          Faker::Number.number(digits: field_value.length).to_s
        else
          Faker::Number.number(digits: field_value.to_s.length)
        end
      end
    end

    # Keep field value recognizable but different to reduce risk of exploitation (e.g., username scraping)
    def mixup_css_id(field_name, field_value)
      case field_name
      when "css_id"
        field_value[4..-1] + field_value[0..3]
      end
    end

    def obfuscate_sentence(field_name, field_value)
      case field_name
      when "instructions", "description", "decision_text", "notes", /_text$/, /_notes$/, /_description$/
        # puts "obfuscate_sentence: #{field_name} = #{field_value}"
        field_value.split.map { |word| word[0..1] }.join(" ")
      when "military_service"
        branch = %w[ARMY AF NAVY M CG].sample
        discharge = ["Honorable", "Under Honorable Conditions"].sample
        start_date = Faker::Date.between(from: "1965-01-01", to: 10.years.ago)
        end_date = start_date + rand(1..10).years + rand(6).months + rand(15).days
        date_format = "%m/%d/%Y"
        "#{branch} #{start_date.strftime(date_format)} - #{end_date.strftime(date_format)}, #{discharge}"
      when "summary"
        <<~HTML
          <p><strong>Contentions</strong>&nbsp;</p>
          <p><span style=\"color: rgb(0,0,255);\">#{Faker::Lorem.sentence(random_words_to_add: 5)}</span></p>
          <p><strong>Evidence</strong>&nbsp;</p>
          <p><span style=\"color: rgb(0,0,255);\">#{Faker::Lorem.sentence(random_words_to_add: 5)}</span></p>
          <p><strong>Comments and special instructions to attorneys</strong>&nbsp;</p>
          <p><span style=\"color: rgb(0,0,255);\">#{Faker::Lorem.sentence(random_words_to_add: 5)}</span></p>
        HTML
      end
    end
  end
end
