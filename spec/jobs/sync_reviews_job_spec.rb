describe SyncReviewsJob do
  context ".perform" do
    let!(:end_product_establishment_more_recently_synced) do
      create(:end_product_establishment, last_synced_at: 1.day.ago, established_at: 4.days.ago)
    end

    let!(:end_product_establishment_less_recently_synced) do
      create(:end_product_establishment, last_synced_at: 2.days.ago, established_at: 4.days.ago)
    end

    let!(:end_product_establishment_never_synced) do
      create(:end_product_establishment, last_synced_at: nil, established_at: 4.days.ago)
    end

    let!(:higher_level_review_requiring_processing) do
      create(:higher_level_review).tap { |hlr| hlr.submit_for_processing! }
    end

    let!(:higher_level_review_processed) do
      create(:higher_level_review).tap { |hlr| hlr.processed! }
    end

    let!(:higher_level_review_attempts_ended) do
      create(
        :higher_level_review,
        establishment_attempted_at: (ClaimReview::REQUIRES_PROCESSING_WINDOW_DAYS + 1).days.ago
      )
    end

    context "when there are canceled or cleared end product establishments" do
      let!(:end_product_establishment_canceled) do
        create(:end_product_establishment, :canceled, established_at: 4.days.ago)
      end

      let!(:end_product_establishment_cleared) do
        create(:end_product_establishment, :cleared, established_at: 4.days.ago)
      end

      it "does not sync them" do
        expect(EndProductSyncJob).to_not receive(:perform_later).with(end_product_establishment_canceled.id)
        expect(EndProductSyncJob).to_not receive(:perform_later).with(end_product_establishment_cleared.id)

        SyncReviewsJob.perform_now("limit" => 2)
      end
    end

    context "where there are claim reviews awaiting processing" do
      it "ignores completed and older expired reviews" do
        expect(EndProductSyncJob).to receive(:perform_later).twice.and_return(true)
        expect(ClaimReviewProcessJob).to_not receive(:perform_later).with(higher_level_review_attempts_ended)
        expect(ClaimReviewProcessJob).to_not receive(:perform_later).with(higher_level_review_processed)
        expect(ClaimReviewProcessJob).to receive(:perform_later).with(higher_level_review_requiring_processing)

        SyncReviewsJob.perform_now("limit" => 2)
      end
    end

    it "prioritizes never synced ramp elections" do
      expect(EndProductSyncJob).to receive(:perform_later).once.with(end_product_establishment_never_synced.id)
      SyncReviewsJob.perform_now("limit" => 1)
    end

    it "prioritizes less recently synced ramp_elections" do
      expect(EndProductSyncJob).to receive(:perform_later).with(end_product_establishment_never_synced.id)
      expect(EndProductSyncJob).to receive(:perform_later).with(end_product_establishment_less_recently_synced.id)

      SyncReviewsJob.perform_now("limit" => 2)
    end

    context "when there are ramp refilings that need to be reprocessed" do
      before do
        allow(RampRefiling).to receive(:need_to_reprocess).and_return([ramp_refiling, ramp_refiling2])
      end

      let(:ramp_refiling) { RampRefiling.new }
      let(:ramp_refiling2) { RampRefiling.new }

      it "attempts to reproccess them" do
        expect(ramp_refiling).to receive(:create_end_product_and_contentions!)
        expect(ramp_refiling2).to receive(:create_end_product_and_contentions!)
        SyncReviewsJob.perform_now
      end

      context "when an error is thrown" do
        it "swallows it and carries on" do
          allow(ramp_refiling).to receive(:create_end_product_and_contentions!).and_raise(StandardError.new)
          expect(ramp_refiling2).to receive(:create_end_product_and_contentions!)
          SyncReviewsJob.perform_now
        end
      end
    end
  end
end
