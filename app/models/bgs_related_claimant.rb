# frozen_string_literal: true

class BgsRelatedClaimant < Claimant
  include AssociatedBgsRecord

  validate { |claimant| ClaimantValidator.new(claimant).validate }

  delegate :date_of_birth,
           :advanced_on_docket?,
           :name,
           :first_name,
           :last_name,
           :middle_name,
           :email_address,
           to: :person
  delegate :address,
           :address_line_1,
           :address_line_2,
           :address_line_3,
           :city,
           :country,
           :state,
           :zip,
           to: :bgs_address_service

  def fetch_bgs_record
    general_info = bgs.fetch_claimant_info_by_participant_id(participant_id)
    name_info = bgs.fetch_person_info(participant_id)

    general_info.merge(name_info)
  end

  def bgs_payee_code
    return unless bgs_record

    bgs_record[:payee_code]
  end

  def bgs_record
    @bgs_record ||= try_and_retry_bgs_record
  end

  def person
    @person ||= Person.find_or_create_by_participant_id(participant_id)
  end

  def representative_participant_id
    power_of_attorney&.participant_id
  end

  private

  def bgs_address_service
    @bgs_address_service ||= BgsAddressService.new(participant_id: participant_id)
  end

  def find_power_of_attorney
    find_power_of_attorney_by_pid || find_power_of_attorney_by_file_number
  end

  def find_power_of_attorney_by_pid
    BgsPowerOfAttorney.find_or_create_by_claimant_participant_id(participant_id)
  rescue ActiveRecord::RecordInvalid # not found at BGS by PID
    nil
  end

  def find_power_of_attorney_by_file_number
    BgsPowerOfAttorney.find_or_create_by_file_number(decision_review.veteran_file_number)
  rescue ActiveRecord::RecordInvalid # not found at BGS
    nil
  end
end
