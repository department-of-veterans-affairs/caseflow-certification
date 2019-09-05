# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe BvaDispatch, :postgres do
  let(:bva_dispatch_org) { BvaDispatch.singleton }

  before do
    create_list(:user, 6).each do |u|
      OrganizationsUser.add_user_to_organization(u, bva_dispatch_org)
    end
  end

  describe ".next_assignee" do
    subject { bva_dispatch_org.next_assignee }

    context "when there are no members of the BVA Dispatch team" do
      before do
        OrganizationsUser.where(organization: bva_dispatch_org).delete_all
      end

      it "should throw an error" do
        expect { subject }.to raise_error do |error|
          expect(error).to be_a(Caseflow::Error::RoundRobinTaskDistributorError)
          expect(error.message).to eq("Assignee pool can't be blank")
        end
      end
    end

    context "when there are members on the BVA Dispatch team" do
      it "should return the first member of the BVA Dispatch team" do
        expect(subject).to eq(bva_dispatch_org.users.first)
      end

      context "when members are admins" do
        let(:number_of_admins) { 3 }

        before do
          admin_ids = OrganizationsUser.where(organization: bva_dispatch_org).take(number_of_admins).map(&:user_id)
          User.where(id: admin_ids).each { |admin| OrganizationsUser.make_user_admin(admin, bva_dispatch_org) }
        end

        it "should skip the admins and assign to the non admin team members" do
          expect(subject).to eq(bva_dispatch_org.users[number_of_admins])
        end
      end
    end
  end

  describe ".automatically_assign_to_member?" do
    subject { bva_dispatch_org.automatically_assign_to_member? }

    it "should return true" do
      expect(subject).to eq(true)
    end

    context "when there are no members of the BVA Dispatch team" do
      before do
        OrganizationsUser.where(organization: bva_dispatch_org).delete_all
      end

      it "should throw an error" do
        expect { subject }.to raise_error do |error|
          expect(error).to be_a(Caseflow::Error::RoundRobinTaskDistributorError)
          expect(error.message).to eq("Assignee pool can't be blank")
        end
      end
    end
  end
end
