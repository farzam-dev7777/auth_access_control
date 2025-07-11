# Clear existing data in correct order to avoid foreign key violations
puts "Clearing existing data..."
ActivityLog.destroy_all
ParticipationRule.destroy_all
ParentalConsent.destroy_all
Membership.destroy_all
Organization.destroy_all
User.destroy_all

puts "Creating sample data for Access Control Assessment Demo..."

# Create sample users with different ages for System 2 demo
users = []

# Adult users (System 1 demo - organization management)
adult_users = [
  { first_name: "John", last_name: "Admin", email: "john@example.com", date_of_birth: 30.years.ago },
  { first_name: "Sarah", last_name: "Manager", email: "sarah@example.com", date_of_birth: 28.years.ago },
  { first_name: "Mike", last_name: "Employee", email: "mike@example.com", date_of_birth: 25.years.ago },
  { first_name: "Lisa", last_name: "Coordinator", email: "lisa@example.com", date_of_birth: 32.years.ago }
]

# Teen users (System 2 demo - age-based access)
teen_users = [
  { first_name: "Alex", last_name: "Teen", email: "alex@example.com", date_of_birth: 16.years.ago },
  { first_name: "Emma", last_name: "Student", email: "emma@example.com", date_of_birth: 15.years.ago }
]

# Child users (System 2 demo - parental consent required)
child_users = [
  { first_name: "Tommy", last_name: "Child", email: "tommy@example.com", date_of_birth: 12.years.ago },
  { first_name: "Sophie", last_name: "Young", email: "sophie@example.com", date_of_birth: 11.years.ago }
]

# Create all users
(adult_users + teen_users + child_users).each do |user_data|
  user = User.create!(
    first_name: user_data[:first_name],
    last_name: user_data[:last_name],
    email: user_data[:email],
    password: "password123",
    date_of_birth: user_data[:date_of_birth]
  )
  users << user
  puts "Created user: #{user.full_name} (#{user.age} years old)"
end

# Create sample organizations for System 1 demo
organizations = []

# Educational organization
educational_org = Organization.create!(
  name: "Tech Academy High School",
  org_type: :educational,
  settings: {
    allow_minors: true,
    requires_parental_consent: true,
    min_age: 13,
    max_age: 18
  }
)
organizations << educational_org

# Corporate organization
corporate_org = Organization.create!(
  name: "Innovation Corp",
  org_type: :corporate,
  settings: {
    allow_minors: false,
    requires_parental_consent: false,
    min_age: 18,
    max_age: 65
  }
)
organizations << corporate_org

# Community organization
community_org = Organization.create!(
  name: "Local Youth Club",
  org_type: :community,
  settings: {
    allow_minors: true,
    requires_parental_consent: true,
    min_age: 10,
    max_age: 25
  }
)
organizations << community_org

puts "Created organizations: #{organizations.map(&:name).join(', ')}"

# Create memberships with different roles for System 1 demo
memberships = []

# Educational organization memberships
Membership.create!(user: users.find { |u| u.email == "john@example.com" }, organization: educational_org, role: :admin)
Membership.create!(user: users.find { |u| u.email == "sarah@example.com" }, organization: educational_org, role: :moderator)
Membership.create!(user: users.find { |u| u.email == "alex@example.com" }, organization: educational_org, role: :member)
Membership.create!(user: users.find { |u| u.email == "emma@example.com" }, organization: educational_org, role: :member)

# Corporate organization memberships
Membership.create!(user: users.find { |u| u.email == "john@example.com" }, organization: corporate_org, role: :admin)
Membership.create!(user: users.find { |u| u.email == "sarah@example.com" }, organization: corporate_org, role: :moderator)
Membership.create!(user: users.find { |u| u.email == "mike@example.com" }, organization: corporate_org, role: :member)
Membership.create!(user: users.find { |u| u.email == "lisa@example.com" }, organization: corporate_org, role: :member)

# Community organization memberships
Membership.create!(user: users.find { |u| u.email == "john@example.com" }, organization: community_org, role: :admin)
Membership.create!(user: users.find { |u| u.email == "alex@example.com" }, organization: community_org, role: :member)
Membership.create!(user: users.find { |u| u.email == "emma@example.com" }, organization: community_org, role: :member)
Membership.create!(user: users.find { |u| u.email == "tommy@example.com" }, organization: community_org, role: :member)

puts "Created memberships with different roles"

# Create parental consent for child users (System 2 demo)
child_users.each do |child_data|
  user = users.find { |u| u.email == child_data[:email] }
  if user.requires_parental_consent?
    ParentalConsent.create!(
      user: user,
      parent_email: "parent.#{user.first_name.downcase}@example.com",
      consent_token: SecureRandom.hex(16),
      consent_requested_at: Time.current,
      expires_at: 7.days.from_now,
      consented: false
    )
    puts "Created parental consent request for: #{user.full_name}"
  end
end

# Create participation rules for organizations (System 1 demo)
organizations.each do |org|
  ParticipationRule.create!(
    organization: org,
    rule_type: "age_restriction",
    conditions: { min_age: org.min_age, max_age: org.max_age },
    actions: { allow_access: true },
    active: true,
    priority: 1,
    description: "Age-based access control"
  )

  ParticipationRule.create!(
    organization: org,
    rule_type: "role_assignment",
    conditions: { allowed_roles: [ "admin", "moderator" ] },
    actions: { can_manage_members: true, can_view_analytics: true },
    active: true,
    priority: 2,
    description: "Role-based permissions"
  )

  puts "Created participation rules for: #{org.name}"
end

# Create activity logs for analytics demo
organizations.each do |org|
  org.memberships.each do |membership|
    ActivityLog.create!(
      user: membership.user,
      organization: org,
      action: "member_joined",
      metadata: { role: membership.role },
      performed_at: membership.created_at
    )
  end

  # Add some recent activities
  ActivityLog.create!(
    user: org.memberships.first.user,
    organization: org,
    action: "rule_updated",
    metadata: { updated_fields: [ "settings" ] },
    performed_at: 2.days.ago
  )

  ActivityLog.create!(
    user: org.memberships.first.user,
    organization: org,
    action: "role_changed",
    metadata: { member: org.memberships.last.user.full_name, new_role: "moderator" },
    performed_at: 1.day.ago
  )
end

puts "Created activity logs for analytics"

puts "\n=== Demo Data Summary ==="
puts "Users created: #{User.count}"
puts "  - Adults: #{User.adults.count}"
puts "  - Minors: #{User.minors.count}"
puts "  - Children requiring consent: #{User.where('date_of_birth > ?', 13.years.ago).count}"
puts "Organizations created: #{Organization.count}"
puts "Memberships created: #{Membership.count}"
puts "Parental consents created: #{ParentalConsent.count}"
puts "Participation rules created: #{ParticipationRule.count}"
puts "Activity logs created: #{ActivityLog.count}"

puts "\n=== Demo Login Credentials ==="
puts "Admin user: john@example.com / password123"
puts "Manager user: sarah@example.com / password123"
puts "Employee user: mike@example.com / password123"
puts "Teen user: alex@example.com / password123"
puts "Child user: tommy@example.com / password123"

puts "\n=== Demo Instructions ==="
puts "1. Login as john@example.com to see admin features"
puts "2. Create new organizations to demonstrate System 1"
puts "3. Add members with different roles"
puts "4. View analytics dashboard"
puts "5. Login as tommy@example.com to see parental consent workflow (System 2)"
puts "6. Explore age-based access controls"

puts "\nSeed data created successfully!"
