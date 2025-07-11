class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :memberships
  has_many :organizations, through: :memberships
  has_many :membership_requests, dependent: :destroy
  has_one :parental_consent, dependent: :destroy

  validates :first_name, :last_name, presence: true
  validates :date_of_birth, presence: true
  validate :minimum_age_requirement
  validate :maximum_age_reasonable

  scope :adults, -> { where("date_of_birth <= ?", 18.years.ago) }
  scope :minors, -> { where("date_of_birth > ?", 18.years.ago) }

  # Virtual attribute to skip personal organization creation
  attr_accessor :skip_personal_organization

  def age
    return nil unless date_of_birth

    ((Time.current - date_of_birth.to_time) / 1.year).floor
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def age_group
    case age
    when 0..12 then :child
    when 13..17 then :teen
    when 18..64 then :adult
    else :senior
    end
  end

  def minor?
    age < 18
  end

  def requires_parental_consent?
    age < 13
  end

  def can_participate_in_organization?(organization)
    return false unless organizations.include?(organization)
    return false if suspended?
    return false if minor? && !has_valid_parental_consent?
    true
  end

  def has_valid_parental_consent?
    return true unless requires_parental_consent?
    parental_consent&.consented? && parental_consent&.valid_consent?
  end

  def suspended?
    suspended
  end

  def suspend!(reason = nil)
    update!(
      suspended: true,
      suspended_at: Time.current,
      suspended_reason: reason
    )
  end

  def unsuspend!
    update!(
      suspended: false,
      suspended_at: nil,
      suspended_reason: nil
    )
  end

  private

  def minimum_age_requirement
    return if date_of_birth.blank?

    if date_of_birth > 10.years.ago
      errors.add(:date_of_birth, "You must be at least 10 years old to register.")
    end
  end

  def maximum_age_reasonable
    return if date_of_birth.blank?

    if date_of_birth < 120.years.ago
      errors.add(:date_of_birth, "Please enter a valid date of birth.")
    end
  end
end
