class BgsPowerOfAttorney
  include ActiveModel::Model
  include AssociatedBgsRecord

  attr_accessor :file_number
  attr_accessor :claimant_participant_id

  bgs_attr_accessor :representative_name, :representative_type, :participant_id

  def representative_address
    @bgs_representative_address ||= load_bgs_address!
  end

  private

  def bgs
    BGSService.new
  end

  def fetch_bgs_record
    if claimant_participant_id
      bgs.fetch_poas_by_participant_ids([claimant_participant_id])[claimant_participant_id]
    else
      bgs.fetch_poa_by_file_number(file_number)
    end
  end

  def load_bgs_address!
    return nil if !participant_id

    return BgsAddressService.new(participant_id: participant_id).fetch_bgs_record
  end
end
