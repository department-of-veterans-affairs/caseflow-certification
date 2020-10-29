# frozen_string_literal: true

describe VirtualHearingRepository, :all_dbs do
  let(:regional_office) { "RO42" }
  let(:hearing_date) { Time.zone.now }
  let(:ama_disposition) { nil }
  let(:hearing_day) do
    create(
      :hearing_day,
      regional_office: regional_office,
      scheduled_for: hearing_date,
      request_type: HearingDay::REQUEST_TYPES[:video]
    )
  end

  let(:hearing) do
    create(:hearing, regional_office: regional_office, hearing_day: hearing_day, disposition: ama_disposition)
  end

  context ".ready_for_deletion" do
    let!(:virtual_hearing) { create(:virtual_hearing, :initialized, status: :active, hearing: hearing) }

    subject { VirtualHearingRepository.ready_for_deletion }

    context "for an AMA hearing" do
      context "that was held" do
        let(:hearing_date) { Time.zone.now - 1.day }

        it "returns the virtual hearing" do
          expect(subject).to eq [virtual_hearing]
        end
      end

      context "that was postponed" do
        let(:ama_disposition) { Constants.HEARING_DISPOSITION_TYPES.postponed }
        let(:hearing_date) { Time.zone.now - 1.day }

        it "returns the virtual hearing" do
          expect(subject).to eq [virtual_hearing]
        end
      end

      context "that was cancelled" do
        let(:ama_disposition) { Constants.HEARING_DISPOSITION_TYPES.cancelled }
        let(:hearing_date) { Time.zone.now - 1.day }

        it "returns the virtual hearing" do
          expect(subject).to eq [virtual_hearing]
        end
      end

      context "on the day of" do
        it "does not return the virtual hearing" do
          expect(subject).to eq []
        end
      end
    end

    context "for a Legacy hearing" do
      let(:legacy_dispositon) { nil }
      let(:hearing) do
        create(
          :legacy_hearing,
          regional_office: regional_office,
          hearing_day_id: hearing_day.id,
          case_hearing: create(:case_hearing, hearing_disp: legacy_dispositon)
        )
      end

      context "that was held" do
        let(:hearing_date) { Time.zone.now - 1.day }

        it "returns the virtual hearing" do
          expect(subject).to eq [virtual_hearing]
        end
      end

      context "that was postponed" do
        let(:legacy_dispositon) { "P" }
        let(:hearing_date) { Time.zone.now - 1.day }

        it "returns the virtual hearing" do
          expect(subject).to eq [virtual_hearing]
        end
      end

      context "that was cancelled" do
        let(:legacy_dispositon) { "C" }
        let(:hearing_date) { Time.zone.now - 1.day }

        it "returns the virtual hearing" do
          expect(subject).to eq [virtual_hearing]
        end
      end

      context "for cancelled virtual hearing" do
        let(:virtual_hearing) { create(:virtual_hearing, status: :cancelled, hearing: hearing) }

        it "returns the virtual hearing" do
          expect(subject).to eq [virtual_hearing]
        end
      end

      context "for pending virtual hearing" do
        let(:virtual_hearing) { create(:virtual_hearing, hearing: hearing) }

        it "does not return the virtual hearing" do
          expect(subject).to eq []
        end
      end

      context "on the day of" do
        it "does not return the virtual hearing" do
          expect(subject).to eq []
        end
      end
    end
  end

  context ".cancelled_hearings_with_pending_emails" do
    subject { VirtualHearingRepository.cancelled_hearings_with_pending_emails }

    let!(:cancelled_vh_with_only_pending_judge_emails) do
      create(:virtual_hearing, :all_emails_sent, status: :cancelled, hearing: hearing)
    end

    let!(:cancelled_vh_with_all_pending_emails) do
      create(:virtual_hearing, :initialized, status: :cancelled, hearing: hearing)
    end

    let!(:cancelled_vh_with_only_pending_rep_email) do
      create(:virtual_hearing, :initialized, status: :cancelled, hearing: hearing)
    end

    it "returns correct virtual hearings" do
      expect(subject.map(&:id)).to contain_exactly(
        cancelled_vh_with_all_pending_emails.id, cancelled_vh_with_only_pending_rep_email.id
      )
    end
  end

  context ".hearings_with_pending_conference_or_pending_emails" do
    subject { VirtualHearingRepository.hearings_with_pending_conference_or_pending_emails }

    let!(:vh_with_pending_conference) do
      create(:virtual_hearing, hearing: hearing)
    end

    let!(:vh_with_all_pending_emails) do
      create(:virtual_hearing, :initialized, status: :active, hearing: hearing)
    end

    let!(:vh_in_good_state) do
      create(:virtual_hearing, :initialized, :all_emails_sent, status: :active, hearing: hearing)
    end

    it "returns correct virtual hearings" do
      expect(subject.map(&:id)).to contain_exactly(
        vh_with_pending_conference.id, vh_with_all_pending_emails.id
      )
    end
  end
end
