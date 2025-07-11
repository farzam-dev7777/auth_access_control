module AccessControl
  extend ActiveSupport::Concern

  included do
    before_action :check_user_access
  end

  private

  def check_user_access
    return unless current_user&.suspended?

    sign_out current_user
    redirect_to new_user_session_path, alert: "Your account has been suspended. Please contact support."
  end

  def ensure_organization_member(organization)
    unless current_user.organizations.include?(organization)
      redirect_to organizations_path, alert: "You do not have access to this organization."
    end
  end

  def ensure_organization_admin(organization)
    membership = current_user.memberships.find_by(organization: organization)
    unless membership&.role == "admin"
      redirect_to organization_path(organization), alert: "Admin access required."
    end
  end

  def ensure_participation_allowed(organization, action = nil)
    service = ParticipationService.new(current_user, organization)

    if action
      unless service.can_perform_action?(action, request_context)
        redirect_to organization_path(organization), alert: "You do not have permission to perform this action."
      end
    else
      unless service.check_age_restrictions
        redirect_to organization_path(organization), alert: "Age restrictions prevent participation in this organization."
      end
    end
  end

  def request_context
    {
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      controller: controller_name,
      action: action_name
    }
  end
end
