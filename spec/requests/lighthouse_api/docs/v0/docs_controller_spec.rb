require "rails_helper"

RSpec.describe LighthouseApi::Docs::V0::DocsController, type: :request do
  describe '#intakes' do
    it 'should successfully return openapi spec' do
      get '/lighthouse_api/docs/v0/intakes'
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      expect(json["openapi"]).to eq('3.0.0')
    end
    describe '/higher_level_review documentation' do
      before(:each) do
        get '/lighthouse_api/docs/v0/intakes'
      end
      let(:hlr_doc){
        json = JSON.parse(response.body)
        json['paths']['/higher_level_review']
      }
      it 'should have POST' do
        expect(hlr_doc).to include('post')
      end
      # TODO when doc is real, verify some other stuff about it
    end
  end
end
