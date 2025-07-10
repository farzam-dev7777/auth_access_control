# Custom Authentication & Access Control System

A Rails application demonstrating organization-based and age-based access control with parental consent workflows.

## Core Features

### Organization-Based Access Control
- **Membership Verification**: Users can join organizations with role-based access
- **Role-Based Permissions**: Admin, moderator, and member roles with different capabilities
- **Organization-Specific Rules**: Custom participation rules per organization
- **Activity Logging**: Basic activity tracking

### Age-Based Participation Rules
- **Age Verification**: Date of birth validation during registration
- **Age-Group Specific Access**: Different access levels based on age groups (Child: 0-12, Teen: 13-17, Adult: 18+)
- **Content Filtering**: Age-appropriate content access
- **Parental Consent Workflow**: Token-based consent system for minors (< 13)

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
   ```

3. **Start the application**
   ```bash
   rails server
   ```

## Usage

### Organization Management

1. **Create Organization**
   - Visit `/organizations/new`
   - Set age restrictions and consent requirements
   - Configure participation rules

2. **Manage Members**
   - View organization members at `/organizations/:id/members`
   - Assign roles and manage permissions

3. **View Activities**
   - Access recent activities at `/organizations/:id/analytics`

### Parental Consent Workflow

1. **For Minors (< 13)**
   - Registration automatically triggers consent requirement
   - Visit `/parental_consents/new` to request consent
   - Enter parent/guardian email

2. **For Parents**
   - Use the consent token provided to access consent request
   - Review child's information and organization details
   - Grant or deny consent

## Database Schema

### Key Models

- **User**: Core user model with age verification and consent tracking
- **Organization**: Organizations with age restrictions and settings
- **Membership**: User-organization relationships with roles
- **ParentalConsent**: Consent workflow for minors
- **ParticipationRule**: Organization-specific participation rules
- **ActivityLog**: Basic activity tracking

### Key Relationships

- Users belong to organizations through memberships
- Users have one parental consent (if required)
- Organizations have many participation rules
- Organizations have many activity logs

## API Endpoints

### Organizations
- `GET /organizations` - List user's organizations
- `GET /organizations/:id` - View organization details
- `POST /organizations` - Create new organization
- `GET /organizations/:id/analytics` - View recent activities
- `GET /organizations/:id/members` - View members

### Parental Consent
- `GET /parental_consents/new` - Request consent form
- `POST /parental_consents` - Submit consent request
- `GET /parental_consents/:token` - Review consent request
- `PATCH /parental_consents/:token/grant` - Grant consent
- `PATCH /parental_consents/:token/deny` - Deny consent

### Participation Rules
- `GET /organizations/:id/participation_rules` - List rules
- `POST /organizations/:id/participation_rules` - Create rule
- `PATCH /organizations/:id/participation_rules/:id` - Update rule
- `DELETE /organizations/:id/participation_rules/:id` - Delete rule

## Security Features

- **Age Verification**: Enforced minimum age requirements
- **Parental Consent**: Required for users under 13
- **Role-Based Access**: Different permissions for different roles
- **Organization Isolation**: Users can only access their organizations
- **Activity Logging**: Basic audit trail
- **Account Suspension**: Support for suspending users

## Development

### Running Tests
```bash
rails test
```

### Code Quality
```bash
bundle exec rubocop
```

### Database Reset
```bash
rails db:reset
```

## License

This project is licensed under the MIT License.
