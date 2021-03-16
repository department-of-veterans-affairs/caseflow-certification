# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module SanitizationTransforms
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
# rubocop:enable Metrics/ModuleLength
