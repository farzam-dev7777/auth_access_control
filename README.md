# Access Control Assessment - Two Systems

## Demo User Credentials

| Name           | Email              | Password     | Role/Org                |
|----------------|--------------------|-------------|-------------------------|
| John Admin     | john@example.com   | password123 | Admin, All Orgs         |
| Sarah Manager  | sarah@example.com  | password123 | Moderator               |
| Mike Employee  | mike@example.com   | password123 | Member                  |
| Lisa Coordinator| lisa@example.com  | password123 | Member                  |
| Alex Teen      | alex@example.com   | password123 | Teen                    |
| Emma Student   | emma@example.com   | password123 | Teen                    |
| Tommy Child    | tommy@example.com  | password123 | Child (Consent needed)  |
| Sophie Young   | sophie@example.com | password123 | Child (Consent needed)  |

> **Note:** For child users, parental consent is required before they can participate in organizations.

---

A Rails application demonstrating **two separate access control systems** as required by the assessment.

## System 1: Organization-Based Access Control

Controls access based on which company/organization someone belongs to.

### Core Features:
- **Organization Membership System**: Verify users work for specific companies
- **Role-Based Permissions**: Admin, Manager, Employee roles with different access levels
- **Organization-Specific Rules**: Custom participation rules per organization
- **Analytics & Reporting**: Dashboard showing usage statistics and activity reports

### Demo Path:
1. Create an organization
2. Add members with different roles
3. Set organization-specific rules
4. View analytics dashboard

---

## System 2: Age-Based Participation Rules

Controls access based on user age with special safeguards for minors.

### Core Features:
- **Age Verification**: Reliable age confirmation during signup
- **Age-Group Specific Areas**: Separate spaces for different age groups
- **Content Filtering**: Age-appropriate content access
- **Parental Consent System**: Required approval for users under 18

### Demo Path:
1. Register users of different ages
2. Show age-specific access areas
3. Demonstrate parental consent workflow
4. Display content filtering

---

## Setup Instructions

### Prerequisites
- Ruby 3.2+
- PostgreSQL

### Installation

1. **Clone and install dependencies**
   ```bash
   git clone <repository-url>
   cd auth_access_control
   bundle install
   ```

2. **Database setup**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```
   > This will create all demo users, organizations, memberships, rules, and logs for a full demo environment.

3. **Start the application**
   ```bash
   rails server
   ```

## Demo Instructions

### System 1 Demo: Organization-Based Access Control

1. **Create Organization**
   - Visit `/organizations/new`
   - Set organization type and settings
   - Configure participation rules

2. **Manage Members**
   - Add members with different roles (Admin, Manager, Employee)
   - View member management at `/organizations/:id/members`
   - Demonstrate role-based permissions

3. **View Analytics**
   - Access analytics dashboard at `/organizations/:id/analytics`
   - Show usage statistics and activity reports

### System 2 Demo: Age-Based Participation Rules

1. **Age Verification**
   - Register users of different ages (child, teen, adult)
   - Show age validation during signup

2. **Age-Specific Access**
   - Demonstrate different access levels based on age
   - Show content filtering for different age groups

3. **Parental Consent Workflow**
   - For users under 18, show consent requirement
   - Walk through parent approval process
   - Demonstrate consent verification

## Key Success Criteria

### Security Features:
- **Secure Authentication**: Devise-based user authentication
- **Role-Based Authorization**: Pundit-based permission system
- **Age Verification**: Enforced minimum age requirements
- **Parental Consent**: Required for users under 18
- **Organization Isolation**: Users can only access their organizations
- **Activity Logging**: Comprehensive audit trail

### Technical Requirements:
- **Clean UI**: Modern, professional interface using Tailwind CSS
- **Responsive Design**: Works on desktop and mobile
- **Database Design**: Proper relationships and constraints
- **API Design**: RESTful endpoints for both systems
- **Documentation**: Clear code and feature documentation

## Database Schema

### Key Models

- **User**: Core user model with age verification
- **Organization**: Organizations with settings and rules
- **Membership**: User-organization relationships with roles
- **ParentalConsent**: Consent workflow for minors
- **ParticipationRule**: Organization-specific rules
- **ActivityLog**: Activity tracking and analytics

### Key Relationships

- Users belong to organizations through memberships
- Users have one parental consent (if required)
- Organizations have many participation rules and activity logs
- Role-based permissions control access levels

## Development

### Running Tests
```bash
bundle exec rspec
```

### Code Quality
```bash
bundle exec rubocop
```

## License

This project is licensed under the MIT License.
