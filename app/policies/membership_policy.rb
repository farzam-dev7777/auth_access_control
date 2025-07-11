class MembershipPolicy < ApplicationPolicy
  def create?
    # Only admins can invite/add members
    Membership.find_by(user: user, organization: record.organization)&.admin?
  end

  def update?
    # Admins and moderators can update roles
    membership = Membership.find_by(user: user, organization: record.organization)
    membership&.admin? || membership&.moderator?
  end

  def destroy?
    # Only admins can remove members
    Membership.find_by(user: user, organization: record.organization)&.admin?
  end
end
