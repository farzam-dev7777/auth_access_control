class ActivityLog < ApplicationRecord
  belongs_to :user
  belongs_to :organization, optional: true

  validates :action, presence: true
  validates :performed_at, presence: true

  scope :recent, ->(days = 30) { where("performed_at >= ?", days.days.ago) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_date_range, ->(start_date, end_date) { where(performed_at: start_date..end_date) }

  ACTIONS = %w[
    user_login
    user_logout
    member_joined
    member_left
    role_changed
    content_posted
    event_created
    event_attended
    consent_granted
    consent_requested
    consent_denied
    consent_viewed
    rule_created
    rule_updated
    rule_deleted
  ].freeze

  validates :action, inclusion: { in: ACTIONS }

  def self.log_activity(user, organization, action, metadata = {})
    # Use anonymous user if no user is provided or if user is nil
    user_to_log = user || User.anonymous_user

    # Validate organization - only use if it's a valid Organization instance
    organization_to_log = nil
    if organization.present? && organization.is_a?(Organization)
      organization_to_log = organization
    end

    create!(
      user: user_to_log,
      organization: organization_to_log,
      action: action,
      metadata: metadata,
      ip_address: metadata[:ip_address],
      user_agent: metadata[:user_agent],
      performed_at: Time.current
    )
  end
end
