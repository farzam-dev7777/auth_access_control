class ParentalConsent < ApplicationRecord
  belongs_to :user

  validates :parent_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :consent_token, presence: true, uniqueness: true
  validates :consent_requested_at, presence: true
  validates :expires_at, presence: true

  before_validation :generate_consent_token, on: :create
  before_validation :set_expiration, on: :create

  scope :pending, -> { where(consented: false).where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  scope :valid_consents, -> { where(consented: true) }

  def consented?
    consented && !expired?
  end

  def expired?
    expires_at <= Time.current
  end

  def valid_consent?
    consented? && !expired?
  end

  def grant_consent!
    update!(
      consented: true,
      consented_at: Time.current
    )
  end

  def self.find_by_token(token)
    find_by(consent_token: token)
  end

  private

  def generate_consent_token
    self.consent_token = SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at = 7.days.from_now
  end
end