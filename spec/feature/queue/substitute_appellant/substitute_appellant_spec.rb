
require_relative "./shared_setup.rb"

RSpec.feature "granting substitute appellant for appeals", :all_dbs do
    describe "with a dismissed appeal" do
        let(:appeal) { create(:appeal, :dispatched) }
        let(:substitution_date) { Time.zone.today - 5.days }
        let(:user) { create(:user) }

        context "as COTB user" do
          include_context "with Clerk of the Board user"
          include_context "with feature toggle"
          include_context "with existing relationships"

          it_should_behave_like "fill substitution form"
        end
    end
end

