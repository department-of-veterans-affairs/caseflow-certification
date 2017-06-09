require "rails_helper"

RSpec.describe "Session", type: :request do
  let(:appeal) { Generators::Appeal.build(vacols_record: :ready_to_certify) }

  before do
    Fakes::AuthenticationService.user_session = {
      "id" => "ANNE MERICA", "roles" => ["Certify Appeal"], "station_id" => "405", "email" => "test@example.com"
    }
  end

  context "when regional office is not set" do
    it "user should not be authenticated" do
      get "/certifications/new/#{appeal.vacols_id}"
      expect(status).to eq 302
    end
  end

  context "when regional office is set" do
    it "user should be authenticated" do
      patch "/sessions/update", regional_office: "RO05"
      expect(status).to eq 200
      get "/certifications/new/#{appeal.vacols_id}"
      expect(status).to_not eq 302
    end
  end
end
