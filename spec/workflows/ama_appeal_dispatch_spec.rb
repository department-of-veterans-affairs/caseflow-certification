# frozen_string_literal: true

require "rails_helper"

describe AmaAppealDispatch do
  describe "#call" do
    it "stores current POA participant ID in the Appeals table" do
      user = create(:user)
      OrganizationsUser.add_user_to_organization(user, BvaDispatch.singleton)
      appeal = create(:appeal, :advanced_on_docket_due_to_age)
      root_task = create(:root_task, appeal: appeal)
      BvaDispatchTask.create_from_root_task(root_task)
      claimant = appeal.claimants.first
      poa_participant_id = "1234567"

      bgs_poa = instance_double(BgsPowerOfAttorney)
      allow(BgsPowerOfAttorney).to receive(:new)
        .with(claimant_participant_id: claimant.participant_id).and_return(bgs_poa)
      allow(bgs_poa).to receive(:participant_id).and_return(poa_participant_id)

      params = {
        appeal_id: appeal.id,
        appeal_type: "Appeal",
        citation_number: "A18123456",
        decision_date: Time.zone.now,
        redacted_document_location: "C://Windows/User/BLOBLAW/Documents/Decision.docx"
      }

      AmaAppealDispatch.new(appeal: appeal, params: params, user: user).call

      expect(appeal.reload.poa_participant_id).to eq poa_participant_id
    end
  end
end
