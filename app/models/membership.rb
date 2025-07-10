class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  enum role: { admin: "admin", moderator: "moderator", member: "member" }
end
