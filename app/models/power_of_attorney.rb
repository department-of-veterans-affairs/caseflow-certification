# A model that centralizes all information
# about the appellant's legal representation.
#
# Power of attorney (also referred to as "representative")
# is tied to the appeal in VACOLS, but it's tied to the veteran
# in BGS - so the two are ofen out of sync.
# This class exposes information from both systems
# and lets the user modify VACOLS with BGS information
# (but not the other way around).
#
# TODO: include the REP table in the VACOLS query and
# fetch representative name information from VACOLS
# TODO: we query VACOLS when the vacols methods are
# called, even if we've also queried VACOLS outside of this
# model but in the same request. is this something we should optimize?
class PowerOfAttorney
  include ActiveModel::Model
  include AssociatedVacolsModel

  vacols_attr_accessor  :vacols_representative_type,
                        :vacols_representative_name

  attr_accessor :bgs_representative_name,
                :bgs_representative_type,
                :bgs_representative_address,
                :bgs_address_not_found,
                :participant_id,
                :vacols_id,
                :file_number

  def load_bgs_record!
    result = bgs.fetch_poa_by_file_number(file_number)
    self.bgs_representative_name = result[:representative_name]
    self.bgs_representative_type = result[:representative_type]
    if result[:participant_id]
      self.participant_id = result[:participant_id]
      load_bgs_address!
    else
      # if we don't have a participant id,
      # we can't find the address.
      self.bgs_address_not_found = true
    end

    self
  end

  def bgs_address
    return nil if bgs_address_not_found
    self.bgs_representative_address ||= load_bgs_address!
  end

  def overwrite_vacols_with_bgs_value
    # case_record.bfso
  end

  def bgs
    @bgs ||= BGSService.new
  end

  private

  def find_bgs_address
    bgs.find_address_by_participant_id(participant_id)
  end

  def load_bgs_address!
    load_bgs_record! unless participant_id
    bgs_address = nil

    begin
      bgs_address = find_bgs_address
    rescue Savon::SOAPFault => e
      on_bgs_adress_error(e)
    end

    self.bgs_representative_address
  end

  def on_bgs_address_error(e)
    self.bgs_address_not_found = true
    # TODO: should this be a Raven exception? it might be noisy.
    return Raven.capture_exception(e) if e.message.include?("No Person found")
    fail e
  end

  class << self
    attr_writer :repository

    def repository
      @repository ||= PowerOfAttorneyRepository
    end
  end
end
