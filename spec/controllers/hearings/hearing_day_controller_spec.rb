# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

describe Hearings::HearingDayController, :all_dbs do
  let(:user) { create(:user, roles: ["Build HearSched"]) }

  before do
    User.authenticate!(user: user)
  end

  context "GET index" do
    let(:params) { {} }

    subject { get :index, params: params, as: :json }

    context "with invalid date range" do
      let(:params) { { start_date: "START_DATE", end_date: "END_DATE" } }

      it "returns 400" do
        expect(subject.status).to eq 400
      end
    end

    context "with invalid RO" do
      let(:params) { { regional_office: "BLAH" } }

      it "returns 400" do
        expect(subject.status).to eq 400
      end
    end

    context "with one hearing day within date range" do
      let!(:hearing_day) do
        create(:hearing_day, scheduled_for: Time.zone.now.to_date)
      end
      let(:params) { { start_date: Time.zone.now.to_date - 2.days } }

      it "returns 200 and the hearing day", :aggregate_failures do
        expect(subject.status).to eq 200
        hearing_days = JSON.parse(subject.body)
        expect(hearing_days["hearings"].size).to eq 1
        expect(hearing_days["hearings"][0]["id"]).to eq hearing_day.id
      end
    end
  end
end
