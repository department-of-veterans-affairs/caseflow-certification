class EndProductEstablishment < ApplicationRecord
  class EstablishedEndProductNotFound < StandardError; end
  attr_accessor :valid_modifiers
  # In AMA reviews, we may create 2 end products at the same time. To avoid using
  # the same modifier, we add used modifiers to the invalid_modifiers array.
  attr_writer :invalid_modifiers
  belongs_to :source, polymorphic: true

  class InvalidEndProductError < StandardError; end

  CANCELED_STATUS = "CAN".freeze

  def perform!
    fail InvalidEndProductError unless end_product_to_establish.valid?
    establish_claim_in_vbms(end_product_to_establish).tap do |result|
      update!(
        reference_id: result.claim_id,
        established_at: Time.zone.now,
        modifier: end_product_to_establish.modifier
      )
    end
  rescue VBMS::HTTPError => error
    raise Caseflow::Error::EstablishClaimFailedInVBMS.from_vbms_error(error)
  end

  # Fetch the resulting end product from the reference_id
  # Add option to either load from BGS or just used cached values
  def result(cached: false)
    cached ? cached_result : fetched_result
  end

  def cached_result
    @cached_result ||= EndProduct.new(
      claim_id: reference_id,
      claim_date: claim_date,
      claim_type_code: code,
      payee_code: payee_code,
      modifier: modifier,
      suppress_acknowledgement_letter: false,
      gulf_war_registry: false,
      station_of_jurisdiction: station
    )
  end

  def fetched_result
    @fetched_result ||= fetch_result
  end

  def description
    reference_id && cached_result.description_with_routing
  end

  # Find an end product that has the traits of the end product that should be created.
  def preexisting_end_product
    @preexisting_end_product ||= veteran.end_products.find { |ep| end_product_to_establish.matches?(ep) }
  end

  def sync!
    # There is no need to sync end_product_status if the status
    # is already inactive since an EP can never leave that state
    return true unless status_active?

    fail EstablishedEndProductNotFound unless result
    update!(
      synced_status: result.status_type_code,
      last_synced_at: Time.zone.now
    )
  end

  def status_canceled?
    synced_status == CANCELED_STATUS
  end

  delegate :contentions, to: :cached_result

  private

  def invalid_modifiers
    @invalid_modifiers || []
  end

  def veteran
    @veteran ||= Veteran.find_or_create_by_file_number(veteran_file_number)
  end

  def establish_claim_in_vbms(end_product)
    VBMSService.establish_claim!(
      claim_hash: end_product.to_vbms_hash,
      veteran_hash: veteran.to_vbms_hash
    )
  end

  def end_product_to_establish
    @end_product_to_establish ||= EndProduct.new(
      claim_id: reference_id,
      claim_date: claim_date,
      claim_type_code: code,
      payee_code: payee_code,
      modifier: find_open_modifier,
      suppress_acknowledgement_letter: false,
      gulf_war_registry: false,
      station_of_jurisdiction: station
    )
  end

  def fetch_result
    return nil unless reference_id

    result = veteran.end_products.find do |end_product|
      end_product.claim_id == reference_id
    end

    fail EstablishedEndProductNotFound unless result
    result
  end

  def taken_modifiers
    @taken_modifiers ||= veteran.end_products.map(&:modifier)
  end

  def find_open_modifier
    return valid_modifiers.first if valid_modifiers.count == 1

    valid_modifiers.each do |modifier|
      if !(taken_modifiers + invalid_modifiers).include?(modifier)
        return modifier
      end
    end
  end

  def status_active?
    !EndProduct::INACTIVE_STATUSES.include?(synced_status)
  end
end
