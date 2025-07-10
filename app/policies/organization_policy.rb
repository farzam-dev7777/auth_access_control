class OrganizationPolicy < ApplicationPolicy
  def show?
    user.organizations.include?(record)
  end

  def manage?
    Membership.find_by(user: user, organization: record)&.admin?
  end
end
