class ActivityLog < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  validates :action, presence: true
  validates :performed_at, presence: true

  scope :recent, ->(days = 30) { where('performed_at >= ?', days.days.ago) }
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
    consent_denied
    rule_created
    rule_updated
    rule_deleted
  ].freeze

  validates :action, inclusion: { in: ACTIONS }

  def self.log_activity(user, organization, action, metadata = {})
    create!(
      user: user,
      organization: organization,
      action: action,
      metadata: metadata,
      ip_address: metadata[:ip_address],
      user_agent: metadata[:user_agent],
      performed_at: Time.current
    )
  end


end