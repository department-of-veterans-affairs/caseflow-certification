# frozen_string_literal: true

class BgsPowerOfAttorney < CaseflowRecord
  include AssociatedBgsRecord
  include BgsService

  has_many :claimants, primary_key: :claimant_participant_id, foreign_key: :participant_id

  CACHED_BGS_ATTRIBUTES = [
    :representative_name,
    :representative_type,
    :authzn_change_clmant_addrs_ind,
    :authzn_poa_access_ind,
    :legacy_poa_cd,
    :poa_participant_id,
    :claimant_participant_id,
    :file_number
  ].freeze

  delegate :email_address,
           to: :person, prefix: :representative

  validates :claimant_participant_id, :poa_participant_id, :representative_name, :representative_type, presence: true

  CACHE_TTL = 30.days

  before_save :update_cached_attributes!

  class << self
    # Neither file_number nor claimant_participant_id is unique by itself,
    # but we treat them that way for easy lookup. They are unique together in our db.
    # Since this is a cache we only want to mirror what BGS has and leave the
    # data integrity to them.
    def find_or_create_by_file_number(file_number)
      find_or_create_by!(file_number: file_number)
    end

    def find_or_create_by_claimant_participant_id(claimant_participant_id)
      find_or_create_by!(claimant_participant_id: claimant_participant_id)
    end
  end

  def representative_name
    cached_or_fetched_from_bgs(attr_name: :representative_name)
  end

  def representative_type
    cached_or_fetched_from_bgs(attr_name: :representative_type)
  end

  def authzn_change_clmant_addrs_ind
    cached_or_fetched_from_bgs(attr_name: :authzn_change_clmant_addrs_ind)
  end

  def authzn_poa_access_ind
    cached_or_fetched_from_bgs(attr_name: :authzn_poa_access_ind)
  end

  def legacy_poa_cd
    cached_or_fetched_from_bgs(attr_name: :legacy_poa_cd)
  end

  def representative_address
    @representative_address ||= load_bgs_address!
  end

  def poa_participant_id
    cached_or_fetched_from_bgs(attr_name: :poa_participant_id, bgs_attr: :participant_id)
  end

  def claimant_participant_id
    cached_or_fetched_from_bgs(attr_name: :claimant_participant_id)
  end

  def file_number
    cached_or_fetched_from_bgs(attr_name: :file_number)
  end

  def stale_attributes?
    return false if bgs_record == :not_found

    stale_attributes.any?
  end

  def update_cached_attributes!
    transaction do
      CACHED_BGS_ATTRIBUTES.each { |attr| send(attr) }
      self.last_synced_at = Time.zone.now
    end
  end

  def found?
    bgs_record.keys.any?
  end

  private

  def person
    @person ||= Person.find_or_create_by(participant_id: poa_participant_id)
  end

  def stale_attributes
    CACHED_BGS_ATTRIBUTES.select { |attr| self[attr].nil? || self[attr] != bgs_record[attr] }
  end

  def cached_or_fetched_from_bgs(attr_name:, bgs_attr: nil)
    bgs_attr ||= attr_name
    self[attr_name] ||= begin
      return unless bgs_record.dig(bgs_attr)

      update!(attr_name => bgs_record[bgs_attr]) if persisted?
      bgs_record[bgs_attr]
    end
  end

  def fetch_bgs_record
    if self[:claimant_participant_id]
      bgs.fetch_poas_by_participant_id(self[:claimant_participant_id])
    elsif self[:file_number]
      bgs.fetch_poa_by_file_number(self[:file_number])
    else
      fail "Must define claimant_participant_id or file_number"
    end
  end

  def load_bgs_address!
    return nil if !participant_id

    BgsAddressService.new(participant_id: poa_participant_id).address
  end
end
