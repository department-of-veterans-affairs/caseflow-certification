# frozen_string_literal: true

class UnrecognizedAppellant < CaseflowRecord
  include HasUnrecognizedPartyDetail

  belongs_to :claimant
  belongs_to :unrecognized_party_detail, dependent: :destroy
  belongs_to :unrecognized_power_of_attorney, class_name: "UnrecognizedPartyDetail", dependent: :destroy

  def power_of_attorney
    @power_of_attorney ||= begin
      if poa_participant_id
        AttorneyPowerOfAttorney.new(poa_participant_id)
      elsif unrecognized_power_of_attorney_id
        UnrecognizedPowerOfAttorney.new(unrecognized_power_of_attorney)
      end
    end
  end

  def update_with_versioning!(_params)
    # Needs to be filled in with update stuff. _params, not params, being used here to pass code climate inspection
    self
  end
end
