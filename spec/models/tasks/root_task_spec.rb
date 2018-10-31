describe RootTask do
  before do
    FeatureToggle.enable!(:test_facols)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  context ".create_root_and_sub_tasks!" do
    let(:participant_id_with_pva) { "1234" }
    let(:participant_id_with_aml) { "5678" }

    let(:appeal) do
      create(:appeal, claimants: [
               create(:claimant, participant_id: participant_id_with_pva),
               create(:claimant, participant_id: participant_id_with_aml)
             ])
    end

    before do
      allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids)
        .with([participant_id_with_pva]).and_return(
          participant_id_with_pva => {
            representative_name: "PARALYZED VETERANS OF AMERICA, INC.",
            representative_type: "POA National Organization",
            participant_id: "2452383"
          }
        )
      allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids)
        .with([participant_id_with_aml]).and_return(
          participant_id_with_aml => {
            representative_name: "VIETNAM VETERANS OF AMERICA",
            representative_type: "POA National Organization",
            participant_id: "2452415"
          }
        )
    end

    let!(:pva) do
      Vso.create(
        name: "Paralyzed Veterans Of America",
        role: "VSO",
        url: "paralyzed-veterans-of-america",
        participant_id: "2452383"
      )
    end

    context "when VSOs exist in our organization table" do
      let!(:vva) do
        Vso.create(
          name: "Vietnam Veterans Of America",
          role: "VSO",
          url: "vietnam-veterans-of-america",
          participant_id: "2452415"
        )
      end

      it "creates a task for each VSO" do
        RootTask.create_root_and_sub_tasks!(appeal)
        expect(RootTask.count).to eq(1)

        expect(GenericTask.count).to eq(2)
        expect(GenericTask.first.assigned_to).to eq(pva)
        expect(GenericTask.second.assigned_to).to eq(vva)
      end

      it "creates RootTask assigned to Bva organization" do
        RootTask.create_root_and_sub_tasks!(appeal)
        expect(RootTask.last.assigned_to).to eq(Bva.singleton)
      end
    end

    context "when only one VSO exists in our organization table" do
      it "doesn't create a GenericTask for missing organization" do
        RootTask.create_root_and_sub_tasks!(appeal)

        expect(GenericTask.count).to eq(1)
        expect(GenericTask.first.assigned_to).to eq(pva)
      end
    end
  end

  describe ".available_actions" do
    let(:user) { FactoryBot.create(:user) }
    let(:root_task) { RootTask.find(FactoryBot.create(:root_task).id) }

    subject { root_task.available_actions(user) }

    context "when user is a member of the Mail team" do
      before { allow_any_instance_of(MailTeam).to receive(:user_has_access?).and_return(true) }

      it "should return a list that includes only the create mail task" do
        expect(subject).to eq([Constants.TASK_ACTIONS.CREATE_MAIL_TASK.to_h])
      end
    end

    context "when user is not a member of the Mail team" do
      it "should return an empty list" do
        expect(subject).to eq([])
      end
    end
  end
end
