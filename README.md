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
   git clone https://github.com/farzam-dev7777/auth_access_control.git
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
   - For users under 13, show consent requirement
   - Walk through parent approval process
   - Demonstrate consent verification
   - Show email notifications and token-based access

## Key Success Criteria

### Security Features:
- **Secure Authentication**: Devise-based user authentication
- **Role-Based Authorization**: Pundit-based permission system
- **Age Verification**: Enforced minimum age requirements
- **Parental Consent**: Required for users under 13 (COPPA compliance)
- **Organization Isolation**: Users can only access their organizations
- **Activity Logging**: Comprehensive audit trail
- **Email Notifications**: Secure token-based parental consent workflow

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

## Parental Consent Workflow

The application implements a comprehensive parental consent system for users under 13 years old, ensuring COPPA (Children's Online Privacy Protection Act) compliance.

### Overview

When a user under 13 registers, they are automatically redirected to a parental consent form where they must:
1. Provide their parent/guardian's email address
2. Select an organization they want to join
3. Submit the consent request

### Workflow Steps

#### 1. **User Registration (Under 13 & Above 10)**
- User registers with age verification
- System detects user is under 13
- User is redirected to parental consent form
- User cannot access other parts of the application until consent is granted

#### 2. **Parental Consent Request Creation**
- User fills out consent form with parent's email
- User selects organization to join
- System creates membership request for the organization
- System generates secure consent token (32-character random string)
- System sends email to parent with secure link

#### 3. **Email Notification to Parent**
- Parent receives professionally formatted email
- Email includes:
  - Child's name and age
  - Organization they want to join
  - Secure token-based link to consent page
  - Clear explanation of what happens next
  - Security information about link expiration

#### 4. **Parent Review and Decision**
- Parent clicks secure link in email
- Parent views consent details and organization information
- Parent can choose to:
  - **Grant Consent**: Approves both consent and organization membership
  - **Deny Consent**: Rejects the request with optional notes

#### 5. **Consent Processing**
- **If Granted**:
  - Consent is marked as approved
  - Membership request is automatically approved
  - User becomes member of the organization
  - User can now access the platform
- **If Denied**:
  - Consent is marked as denied
  - Membership request is rejected
  - User remains restricted from platform access

### Security Features

#### **Token-Based Access**
- Each consent request generates a unique 32-character token
- Tokens are URL-safe and cryptographically secure
- Tokens expire after 7 days for security
- Tokens are single-use and tied to specific consent requests

#### **Email Security**
- Professional HTML and text email templates
- Secure links that don't require parent authentication
- Clear security information and expiration warnings
- Audit trail of all email communications

#### **Access Control**
- Users under 13 cannot access the platform without consent
- Users with pending consent requests are blocked
- Users with valid consent can access all features
- System prevents duplicate consent requests

### Technical Implementation

#### **Models**
- `ParentalConsent`: Stores consent requests, tokens, and status
- `MembershipRequest`: Links consent to organization membership
- `ActivityLog`: Tracks all consent-related activities

#### **Controllers**
- `ParentalConsentsController`: Handles consent creation and processing
- `ParentalConsentMailer`: Sends email notifications to parents

#### **Key Methods**
```ruby
# Check if user requires parental consent
user.requires_parental_consent? # Returns true if age < 13

# Check if user has valid consent
user.has_valid_parental_consent? # Returns true if consent granted and not expired

# Check consent status
consent.pending? # Returns true if consent requested but not yet processed
consent.consented? # Returns true if consent granted and not expired
consent.expired? # Returns true if consent token has expired
```

### Email Templates

The system includes professionally designed email templates:
- **HTML Version**: Beautiful, responsive design with clear call-to-action
- **Text Version**: Plain text fallback for better email client compatibility
- **Content**: Includes child's information, organization details, and security notes

### Activity Logging

All consent-related activities are logged for audit purposes:
- `consent_requested`: When user creates consent request
- `consent_viewed`: When parent views consent page
- `consent_granted`: When parent grants consent
- `consent_denied`: When parent denies consent

### Demo Scenarios

#### **Scenario 1: Successful Consent**
1. Register as 11-year-old user
2. Fill out parental consent form
3. Check email for consent link
4. Click link and grant consent
5. Verify user can now access platform

#### **Scenario 2: Denied Consent**
1. Register as 11-year-old user
2. Fill out parental consent form
3. Check email for consent link
4. Click link and deny consent
5. Verify user remains restricted

#### **Scenario 3: Expired Consent**
1. Register as 11-year-old user
2. Fill out parental consent form
3. Wait 7 days for token expiration
4. Try to access consent link
5. Verify expired message is shown

### Admin Features

Administrators can view all parental consent requests:
- Access via `/parental_consents` (admin only)
- View pending, granted, and denied requests
- See consent details and timestamps
- Monitor consent workflow status

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
