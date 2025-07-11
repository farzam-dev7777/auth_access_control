class OrganizationPolicy < ApplicationPolicy
  def show?
    user.organizations.include?(record)
  end

  def manage?
    Membership.find_by(user: user, organization: record)&.admin?
  end

  def analytics?
    membership = Membership.find_by(user: user, organization: record)
    membership&.admin? || membership&.moderator?
  end

  def export_analytics?
    analytics?
  end

  def generate_report?
    analytics?
  end
end
