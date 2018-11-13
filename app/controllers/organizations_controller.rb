class OrganizationsController < ApplicationController
  before_action :verify_organization_access
  before_action :verify_role_access
  before_action :set_application
  skip_before_action :deny_vso_access

  def show
    render "organizations/show"
  end

  private

  def verify_organization_access
    if organization && organization.is_a?(JudgeTeam.name)
      return true if organization == JudgeTeam.for_judge(current_user)
      redirect_to "/unauthorized"
    end
    redirect_to "/unauthorized" unless organization && organization.user_has_access?(current_user)
  end

  def verify_role_access
    verify_authorized_roles(organization.role) if organization.role
  end

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def organization_url
    params[:url]
  end

  def organization
    # Allow the url to be the ID of the row in the table since this will be what is associated with
    # tasks assigned to the organization in the tasks table.
    Organization.find_by(url: organization_url) || Organization.find(organization_url)
  end
  helper_method :organization
end
