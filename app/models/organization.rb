class Organization < ApplicationRecord
  has_many :memberships
  has_many :users, through: :memberships
  has_many :membership_requests, dependent: :destroy
  has_many :participation_rules, dependent: :destroy
  has_many :activity_logs, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :org_type, presence: true

  enum :org_type, {
    educational: 0,
    nonprofit: 1,
    corporate: 2,
    community: 3
  }

  scope :allowing_minors, -> { where("settings->>'allow_minors' = 'true'") }

  def admins
    users.joins(:memberships).where(memberships: { role: 'admin' })
  end

  def can_user_join?(user)
    return false if user.minor? && !allow_minors
    return false if min_age && user.age < min_age
    return false if max_age && user.age > max_age
    true
  end

  def active_members_count
    memberships.joins(:user).count
  end

  def min_age
    settings&.[]('min_age')&.to_i
  end

  def max_age
    settings&.[]('max_age')&.to_i
  end

  def allow_minors
    settings&.[]('allow_minors') == true || settings&.[]('allow_minors') == "true"
  end

  def requires_parental_consent
    settings&.[]('requires_parental_consent') == true || settings&.[]('requires_parental_consent') == "true"
  end
end
