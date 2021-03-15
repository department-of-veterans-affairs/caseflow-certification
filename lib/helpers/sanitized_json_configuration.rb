# frozen_string_literal: true

require "helpers/association_wrapper.rb"

# Configuration for exporting/importing data from/to Caseflow.

class SanitizedJsonConfiguration

  # The :retrieval lambda is run according to the ordering in this hash.
  EXPORTER_CONFIG = {
    Appeal => {
      track_imported_ids: true,
      sanitize_fields: %w[veteran_file_number],
    },
    User => {
      track_imported_ids: true,
      sanitize_fields: %w[full_name email css_id],
      retrieval: ->(records) { 
        tasks = records[Task]
        cavc_remands = records[CavcRemand]
        hearings = records[Hearing]

        tasks.map(&:assigned_by).compact + tasks.map(&:cancelled_by).compact +
        tasks.assigned_to_user.map(&:assigned_to) +
        cavc_remands.map { |cavc_remand| [cavc_remand.created_by, cavc_remand.updated_by] }.flatten.uniq.compact +
        records[Appeal].map(&:intake).compact.map(&:user).uniq.compact +
        records[AppealIntake].map { |intake| intake&.user }.uniq.compact +
        records[HearingDay].map { |hd| [hd.created_by, hd.updated_by, hd.judge] }.flatten.uniq.compact +
        hearings.map { |h| [h.created_by, h.updated_by, h.judge] }.flatten.uniq.compact +
        hearings.map(&:virtual_hearing).uniq.compact.map { |vh| [vh.created_by, vh.updated_by] }.flatten.uniq.compact 
      }
    },
    Organization => {
      track_imported_ids: true,
      sanitize_fields: %w[],
      retrieval: ->(records) { records[Task].assigned_to_org.map(&:assigned_to) + records[User].map(&:organizations).flatten.uniq }
    },
    Person => {
      track_imported_ids: true,
      sanitize_fields: %w[date_of_birth email_address first_name last_name middle_name ssn],
      retrieval: ->(records) { (records[Veteran] + records[Claimant]).map(&:person).uniq.compact }
    },

    OrganizationsUser => {
      # TODO: Investigate why enabling this breaks things: track_imported_ids: true,
      retrieval: ->(records) { OrganizationsUser.where(user: records[User]) }
    },
    Veteran => {
      sanitize_fields: %w[first_name last_name middle_name file_number ssn],
      retrieval: ->(records) { records[Appeal].map(&:veteran) }
    },
    AppealIntake => {
      sanitize_fields: %w[veteran_file_number],
      retrieval: ->(records) { records[Appeal].map(&:intake) }
    },
    Claimant => {
      retrieval: ->(records) { records[Appeal].map(&:claimants).flatten }
    },
    Task => {
      sanitize_fields: %w[instructions],
      retrieval: ->(records) { records[Appeal].map(&:tasks).flatten.sort_by(&:id).extend(TaskAssignment) }
    },
    TaskTimer => {
      retrieval: ->(records) { TaskTimer.where(task_id: records[Task].map(&:id)) }
    },
    CavcRemand => {
      # cavc_judge_full_name is selected from Constants::CAVC_JUDGE_FULL_NAMES; no need to sanitize
      sanitize_fields: %w[instructions],
      retrieval: ->(records) { records[Appeal].map(&:cavc_remand).compact }
    },

    RequestIssue => {
      sanitize_fields: ["notes", /_(notes|text|description)/],
      retrieval: ->(records) { records[Appeal].map(&:request_issues).flatten }
    },
    DecisionIssue => {
      sanitize_fields: %w[description decision_text],
      retrieval: ->(records) { records[Appeal].map(&:decision_issues).flatten }
    },
    RequestDecisionIssue => {
      retrieval: ->(records) { RequestDecisionIssue.where(request_issue: records[RequestIssue]) }
    },

    Hearing => {
      sanitize_fields: %w[notes military_service summary bva_poc representative_name witness],
      retrieval: ->(records) { records[Task].with_type("HearingTask").map(&:hearing).uniq.compact }
    },
    HearingDay => {
      sanitize_fields: %w[bva_poc notes],
      retrieval: ->(records) { records[Hearing].map(&:hearing_day).uniq.compact }
    },
    VirtualHearing => {
      sanitize_fields: %w[alias guest_pin host_pin guest_pin_long host_pin_long representative_email
                         judge_email alias_with_host appellant_email host_hearing_link guest_hearing_link],
      retrieval: ->(records) { records[Hearing].map(&:virtual_hearing).uniq.compact }
    },
    HearingTaskAssociation => {
      retrieval: ->(records) { HearingTaskAssociation.where(hearing: records[Hearing]) }
    },
  }

  IMPORTER_CONFIG = {

  }

  DIFFERENCE_CONFIG = {

  }

  def self.extract_configuration(config_field, configuration, default_value = nil)
    configuration.map {|clazz, class_config| [clazz, class_config[config_field] || default_value.clone]}.to_h.compact
  end

  def self.extract_classes_with_true(config_field, configuration)
    configuration.select {|_, config| config[config_field] == true }.keys.compact
  end

  SANITIZE_FIELDS = extract_configuration(:sanitize_fields, EXPORTER_CONFIG, []).freeze

  # Special types that can have `same_unique_attributes?`
  # or where we want to look up its id, e.g. Appeal for Claimant used in `same_unique_attributes?`
  # The id are tracked in `importer.id_mapping`.
  ID_MAPPING_TYPES = extract_classes_with_true(:track_imported_ids, EXPORTER_CONFIG).freeze

  # Types that need to be examine for associations so that '_id' fields can be updated
  REASSOCIATE_TYPES = (EXPORTER_CONFIG.keys - ID_MAPPING_TYPES + [DecisionReview]).uniq

  # in case a Class is associated with a specific decendant of one of the REASSOCIATE_TYPES
  REASSOCIATE_TYPES_DESCENDANTS = REASSOCIATE_TYPES.map(&:descendants).flatten
  KNOWN_TYPES = (REASSOCIATE_TYPES + REASSOCIATE_TYPES_DESCENDANTS).uniq # - (ID_MAPPING_TYPES - [Appeal])
  KNOWN_TYPE_NAMES = KNOWN_TYPES.map(&:name)

  # To-do: load this from a file or automatically determine fields to sanitize
  # modelClass => fieldnames_array
  # rubocop:disable Style/MultilineBlockChain
  OFFSET_ID_FIELDS ||= REASSOCIATE_TYPES.map do |clazz|
    [clazz, AssocationWrapper.grouped_fieldnames_of_typed_associations_with(clazz, KNOWN_TYPE_NAMES).values.flatten.sort]
  end.to_h.tap do |class_to_fieldnames_hash|
    # array of decision_issue_ids; not declared as an association in Rails, so add it manually
    class_to_fieldnames_hash[CavcRemand].push("decision_issue_ids").sort!

    # TODO: Why is :participant_id listed as a association? Why is it a symbol whereas others are strings?
    class_to_fieldnames_hash[Claimant].delete(:participant_id)
  end.compact.freeze
  # rubocop:enable Style/MultilineBlockChain

  # For each REASSOCIATE_TYPES, identify their associations so the '_id' fields can be updated based on imported records
  # TODO: consider using KNOWN_TYPES instead of REASSOCIATE_TYPES,
  # or consolidating e.g. TranscriptionTask => ["assigned_to_id", "appeal_id"] with that of Task
  REASSOCIATE_FIELDS ||= {
    # These untyped association fields will associate to the User ActiveRecord
    "User" => REASSOCIATE_TYPES.map do |clazz|
      [clazz, AssocationWrapper.fieldnames_of_untyped_associations_with(User, clazz)]
    end.to_h.compact,

    # These typed polymorphic association fields will associate to the their corresponding ActiveRecord
    :type => REASSOCIATE_TYPES.map do |clazz|
      [clazz, AssocationWrapper.fieldnames_of_typed_associations_for(clazz, OFFSET_ID_FIELDS[clazz])]
    end.to_h.compact
  }.freeze

  # ==========  Exporter Configuration ==============

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
  class << self
    def records_to_export(initial_appeals)
      associated_appeals = initial_appeals.map { |appeal| appeals_associated_with(appeal) }.flatten.uniq.compact
      appeals = (initial_appeals + associated_appeals).uniq

      export_records = {
        Appeal => appeals,
      }
      # incrementally update export_records as subsequent calls may rely on prior updates to export_records
      retrieval_lambdas = extract_configuration(:retrieval, EXPORTER_CONFIG, ->(records) { [] })

      retrieval_lambdas.reject { |clazz, _| ID_MAPPING_TYPES.include?(clazz) }
        .map { |clazz, retrieval_lambda| export_records[clazz] ||= retrieval_lambda.call(export_records) }

      retrieval_lambdas.select { |clazz, _| ID_MAPPING_TYPES.include?(clazz) }
        .map { |clazz, retrieval_lambda| export_records[clazz] ||= retrieval_lambda.call(export_records) }

      export_records[OrganizationsUser] = retrieval_lambdas[OrganizationsUser].call(export_records)
      export_records
    end

    def appeals_associated_with(appeal)
      appeal.cavc_remand&.source_appeal
      # To-do: include other source appeals, e.g., those with the same docket number
    end

    def before_sanitize_hook(record, obj_hash)
      case record
      when User
        # User#attributes includes `display_name`; don't need it when importing so leave it out
        obj_hash.delete(:display_name)
      end
    end

    # To-do: generate the automatically
    TRANSFORM_METHODS = [:mixup_css_id,
                         :random_person_name, :invalid_ssn, :random_email,
                         :obfuscate_sentence, :similar_date, :random_pin].freeze

    def transform_methods
      TRANSFORM_METHODS
    end

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

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
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
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

    def similar_date(field_name, field_value)
      case field_name
      when "date_of_birth"
        case field_value
        when Date
          Faker::Date.between_except(from: field_value - 1.year,
                                     to: field_value, excepted: field_value)
        when /^\d{4}-\d{2}-\d{2}$/
          Faker::Date.between_except(from: Date.parse(field_value) - 1.year,
                                     to: field_value, excepted: field_value).to_json
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

  # ==========  Importer Configuration ==============

  # Classes that shouldn't be imported if a record with the same unique attributes already exists
  NONDUPLICATE_TYPES = [Organization, User, Veteran, Person].freeze

  # During record creation, types where validation and callbacks should be avoided
  TYPES_THAT_SKIP_VALIDATION_AND_CALLBACKS = [Task, *Task.descendants].freeze

  # Start with important types that other records will reassociate with
  FIRST_TYPES_TO_IMPORT = [Appeal, User, Organization, HearingDay].freeze

  class << self
    def check_first_imports(imported_records)
      if imported_records[Appeal.table_name].blank?
        fail "Warning: No appeal imported, aborting import of remaining records"
      end
    end

    # :reek:FeatureEnvy
    def same_unique_attributes?(existing_record, obj_hash, importer: nil)
      case existing_record
      when Organization
        existing_record.url == obj_hash["url"]
      when User
        existing_record.css_id == obj_hash["css_id"]
      when Claimant
        # check if claimant is associated with appeal we just imported
        imported_appeal_id = importer.id_mapping[Appeal.name][obj_hash["decision_review_id"]]
        existing_record.decision_review_id == imported_appeal_id
      when Person
        # To-do: Person.connection.index_exists? :people, :participant_id
        # To-do: ActiveRecord::Base.connection.indexes(Person.table_name).select{|idx| idx.unique}
        existing_record.participant_id == obj_hash["participant_id"]
      end
    end

    def create_singleton(clazz, obj_hash, obj_description)
      # Handle Organization type specially because each organization has a `singleton`
      # To-do: update dev's seed data to match prod's Organization#singleton record ids
      if clazz == Organization && !org_already_exists?(obj_hash)
        puts "  + Creating #{clazz} '#{obj_hash['name']}' with its original id #{obj_hash['id']} \n\t#{obj_description}"
        clazz.create!(obj_hash)
      end
    end

    def org_already_exists?(obj_hash)
      Organization.find_by(url: obj_hash["url"]) || Organization.find_by(id: obj_hash["id"])
    end

    # :reek:FeatureEnvy
    def adjust_unique_identifiers(clazz, obj_hash)
      if clazz <= Organization
        obj_hash["url"] += "_imported" if Organization.find_by(url: obj_hash["url"])
      elsif clazz <= User
        # Change CSS_ID if it already exists for a user with different user.id
        obj_hash["css_id"] += "_imported" if User.find_by_css_id(obj_hash["css_id"])
      end
    end

    def before_creation_hook(clazz, obj_hash, obj_description, importer: nil)
      puts "  + Creating #{clazz} #{obj_hash['id']} \n\t#{obj_description}"
      remaining_id_fields = obj_hash.select do |field_name, field_value|
        field_name.ends_with?("_id") && field_value.is_a?(Integer) && (field_value < importer.id_offset) &&
          (
            !(clazz <= Task && field_name == "assigned_to_id" && obj_hash["assigned_to_type"] == "Organization") &&
            !(clazz <= OrganizationsUser && field_name == "organization_id")
            # !(clazz <= OrganizationsUser && field_name == "user_id")
          )
      end
      unless remaining_id_fields.blank?
        fail "!! For #{clazz}, expecting these *'_id' fields be adjusted: " \
             "#{remaining_id_fields}\n\tobj_hash: #{obj_hash}"
      end
    end
  end
end
