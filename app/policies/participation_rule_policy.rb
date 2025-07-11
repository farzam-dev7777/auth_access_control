class ParticipationRulePolicy < ApplicationPolicy
  def index?
    user.organizations.include?(record.organization)
  end

  def create?
    Membership.find_by(user: user, organization: record.organization)&.admin?
  end

  def update?
    Membership.find_by(user: user, organization: record.organization)&.admin?
  end

  def destroy?
    Membership.find_by(user: user, organization: record.organization)&.admin?
  end
end