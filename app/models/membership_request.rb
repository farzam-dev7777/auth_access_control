class MembershipRequest < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  validates :status, presence: true
  validates :user_id, uniqueness: { scope: :organization_id, message: "has already requested to join this organization" }

  enum :status, {
    pending: "pending",
    approved: "approved",
    rejected: "rejected"
  }

  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :rejected, -> { where(status: "rejected") }

  def approve!
    update!(status: "approved")
    # Create membership when approved
    Membership.create!(user: user, organization: organization, role: "member")
  end

  def reject!
    update!(status: "rejected")
  end
end
