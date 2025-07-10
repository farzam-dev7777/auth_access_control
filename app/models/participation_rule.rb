class ParticipationRule < ApplicationRecord
  belongs_to :organization

  validates :rule_type, presence: true
  validates :priority, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :by_priority, -> { order(priority: :desc) }

  RULE_TYPES = %w[
    event_creation
    content_posting
    member_invitation
    role_assignment
    content_access
    age_restriction
  ].freeze

  validates :rule_type, inclusion: { in: RULE_TYPES }

  def evaluate(user, context = {})
    return false unless active?

    case rule_type
    when 'event_creation'
      evaluate_event_creation(user, context)
    when 'content_posting'
      evaluate_content_posting(user, context)
    when 'member_invitation'
      evaluate_member_invitation(user, context)
    when 'role_assignment'
      evaluate_role_assignment(user, context)
    when 'content_access'
      evaluate_content_access(user, context)
    when 'age_restriction'
      evaluate_age_restriction(user, context)
    else
      false
    end
  end

  def allowed_roles
    conditions['allowed_roles'] || []
  end

  def minimum_age
    conditions['minimum_age']
  end

  def maximum_age
    conditions['maximum_age']
  end

  def required_consent
    conditions['required_consent'] || false
  end

  private

  def evaluate_event_creation(user, context)
    return false unless user.memberships.exists?(organization: organization)

    membership = user.memberships.find_by(organization: organization)
    return true if allowed_roles.include?(membership.role)

    false
  end

  def evaluate_content_posting(user, context)
    return false unless user.memberships.exists?(organization: organization)

    membership = user.memberships.find_by(organization: organization)
    return true if allowed_roles.include?(membership.role)

    false
  end

  def evaluate_member_invitation(user, context)
    membership = user.memberships.find_by(organization: organization)
    return false unless membership&.role == 'admin'

    true
  end

  def evaluate_role_assignment(user, context)
    membership = user.memberships.find_by(organization: organization)
    return false unless membership&.role == 'admin'

    true
  end

  def evaluate_content_access(user, context)
    return false unless user.memberships.exists?(organization: organization)

    if minimum_age && user.age < minimum_age
      return false
    end

    if maximum_age && user.age > maximum_age
      return false
    end

    if required_consent && user.minor? && !user.has_valid_parental_consent?
      return false
    end

    true
  end

  def evaluate_age_restriction(user, context)
    if minimum_age && user.age < minimum_age
      return false
    end

    if maximum_age && user.age > maximum_age
      return false
    end

    true
  end
end