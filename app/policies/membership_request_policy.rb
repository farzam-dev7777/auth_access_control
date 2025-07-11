class MembershipRequestPolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def approve?
    Membership.find_by(user: user, organization: record.organization)&.admin?
  end

  def reject?
    Membership.find_by(user: user, organization: record.organization)&.admin?
  end

  def destroy?
    record.user == user
  end
end