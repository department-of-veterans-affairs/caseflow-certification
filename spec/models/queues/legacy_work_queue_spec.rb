describe LegacyWorkQueue do
  before do
    FeatureToggle.enable!(:test_facols)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  context ".tasks_with_appeals" do
    let(:user) { User.find_or_create_by(css_id: "DNYGLVR", station_id: "LANCASTER") }

    let!(:appeals) do
      [
        create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user)),
        create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user))
      ]
    end

    subject { LegacyWorkQueue.tasks_with_appeals(user, role) }

    context "when it is an attorney" do
      let(:role) { "Attorney" }

      it "returns tasks" do
        expect(subject[0].length).to eq(2)
        expect(subject[0][0].class).to eq(AttorneyLegacyTask)
      end

      it "returns appeals" do
        expect(subject[1].length).to eq(2)
        expect(subject[1][0].class).to eq(LegacyAppeal)
      end
    end

    context "when it is a judge" do
      let(:role) { "Judge" }

      it "returns tasks" do
        expect(subject[0].length).to eq(2)
        expect(subject[0][0].class).to eq(JudgeLegacyTask)
      end

      it "returns appeals" do
        expect(subject[1].length).to eq(2)
        expect(subject[1][0].class).to eq(LegacyAppeal)
      end
    end
  end

  context ".tasks_with_appeals_by_appeal_id" do
    let(:user) { User.find_or_create_by(css_id: "DNYGLVR", station_id: "LANCASTER") }

    let!(:appeals) do
      [
        create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user)),
        create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user))
      ]
    end
    let!(:appeal) { appeals[0] }

    subject { LegacyWorkQueue.tasks_with_appeals_by_appeal_id(appeal.vacols_id, role) }

    context "when the user is a colocated admin" do
      let(:role) { "Colocated" }

      it "returns a task" do
        expect(subject[0].length).to eq(1)
        expect(subject[0][0].class).to eq(LegacyTask)
      end

      it "returns an appeal" do
        expect(subject[1].length).to eq(1)
        expect(subject[1][0].class).to eq(LegacyAppeal)
      end
    end
  end
end
