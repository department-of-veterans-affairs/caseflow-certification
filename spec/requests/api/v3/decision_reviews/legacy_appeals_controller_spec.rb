# frozen_string_literal: true

describe Api::V3::DecisionReviews::LegacyAppealsController, :all_dbs, type: :request do
  before { FeatureToggle.enable!(:api_v3_legacy_appeals) }
  after { FeatureToggle.disable!(:api_v3_legacy_appeals) }

  let(:api_key) { ApiKey.create!(consumer_name: "ApiV3 Test Consumer").key_string }

  # objects related to our test veteran
  let!(:vacols_case) { create(:case_with_decision, :status_active, bfcorlid: "123456789S") }
  let!(:vacols_case_2) { create(:case_with_decision, :status_complete, bfcorlid: "123456789S") }
  let!(:legacy_appeal) { create(:legacy_appeal, :with_veteran, vbms_id: "123456789S", vacols_case: vacols_case) }
  let!(:legacy_appeal_2) { create(:legacy_appeal, vbms_id: "123456789S", vacols_case: vacols_case_2) }

  let(:veteran) { legacy_appeal.veteran }

  # objects unrelated to our test veteran
  let!(:vacols_case_3) { create(:case, bfcorlid: "987654321S") }
  let!(:legacy_appeal_3) { create(:legacy_appeal, :with_veteran, vbms_id: "987654321S", vacols_case: vacols_case_3) }

  describe "#index" do
    context "when SSN used" do
      it "returns active legacy appeals associated with the veteran" do
        get_legacy_appeals(veteran.ssn)
        legacy_appeals = JSON.parse(response.body)["data"]

        expect(response).to have_http_status(:ok)
        expect(legacy_appeals.size).to eq 1

        legacy_appeals.each do |a|
          appeal = LegacyAppeal.find(a["id"])
          expect(appeal.veteran_file_number).to eq veteran.file_number
          expect(appeal.status).to eq "Active"
        end
      end
    end

    context "when file number used" do
      it "returns active legacy appeals associated with the veteran" do
        get_legacy_appeals(veteran.file_number)
        legacy_appeals = JSON.parse(response.body)["data"]

        expect(response).to have_http_status(:ok)
        expect(legacy_appeals.size).to eq 1

        legacy_appeals.each do |a|
          appeal = LegacyAppeal.find(a["id"])
          expect(appeal.veteran_file_number).to eq veteran.file_number
          expect(appeal.status).to eq "Active"
        end
      end
    end

    def get_legacy_appeals(file_number = nil, ssn = nil)
      headers = { "Authorization": "Token #{api_key}", "X-VA-File-Number": file_number, "X-VA-SSN": ssn }

      get("/api/v3/decision_reviews/legacy_appeals", headers: headers)
    end
  end
end
