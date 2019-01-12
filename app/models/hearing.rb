class Hearing < ApplicationRecord
  belongs_to :hearing_day
  belongs_to :appeal
  belongs_to :judge, class_name: "User"
  has_many :hearing_views, as: :hearing

  UUID_REGEX = /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/.freeze

  delegate :scheduled_for, to: :hearing_day
  delegate :request_type, to: :hearing_day
  delegate :veteran_first_name, to: :appeal
  delegate :veteran_last_name, to: :appeal
  delegate :appellant_first_name, to: :appeal
  delegate :appellant_last_name, to: :appeal
  delegate :appellant_city, to: :appeal
  delegate :appellant_state, to: :appeal
  delegate :veteran_age, to: :appeal
  delegate :veteran_gender, to: :appeal
  delegate :veteran_file_number, to: :appeal
  delegate :docket_number, to: :appeal
  delegate :docket_name, to: :appeal
  delegate :external_id, to: :appeal, prefix: true

  def self.find_hearing_by_uuid_or_vacols_id(id)
    if UUID_REGEX.match?(id)
      find_by_uuid!(id)
    else
      LegacyHearing.find_by!(vacols_id: id)
    end
  end

  def master_record
    false
  end

  #:nocov:
  # This is all fake data that will be refactored in a future PR.
  def regional_office_key
    "RO19"
  end

  def regional_office_name
    "Winston-Salem, NC"
  end

  def type
    request_type
  end
  #:nocov:

  def external_id
    uuid
  end

  def military_service
    super || begin
      update(military_service: appeal.veteran.periods_of_service.join("\n")) if persisted? && appeal.veteran
      super
    end
  end

  def to_hash_for_worksheet(_current_user_id)
    serializable_hash(
      methods: [
        :external_id,
        :veteran_first_name,
        :veteran_last_name,
        :appellant_first_name,
        :appellant_last_name,
        :appellant_city,
        :appellant_state,
        :regional_office_name,
        :request_type,
        :judge,
        :scheduled_for,
        :veteran_age,
        :veteran_gender,
        :appeal_external_id,
        :veteran_file_number,
        :docket_number,
        :docket_name,
        :military_service
      ]
    )
  end
end
