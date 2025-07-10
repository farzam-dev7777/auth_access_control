# RSpec Test Suite

This directory contains the test suite for the Authentication & Access Control system.

## Running Tests

### Run all tests
```bash
bundle exec rspec
```

### Run specific test files
```bash
bundle exec rspec spec/models/user_spec.rb
bundle exec rspec spec/models/organization_spec.rb
bundle exec rspec spec/services/participation_service_spec.rb
```

### Run tests with documentation format
```bash
bundle exec rspec --format documentation
```

### Run tests for specific examples
```bash
bundle exec rspec -e "User#age"
```

## Test Structure

### Models
- `spec/models/user_spec.rb` - User model tests
- `spec/models/organization_spec.rb` - Organization model tests
- `spec/models/participation_rule_spec.rb` - ParticipationRule model tests
- `spec/models/parental_consent_spec.rb` - ParentalConsent model tests
- `spec/models/activity_log_spec.rb` - ActivityLog model tests

### Services
- `spec/services/participation_service_spec.rb` - ParticipationService tests

### Factories
- `spec/factories/` - FactoryBot factories for test data

### Support Files
- `spec/support/devise.rb` - Devise test helpers
- `spec/support/factory_bot.rb` - FactoryBot configuration

## Test Coverage

The test suite covers:

1. **Model Validations** - All model validations and associations
2. **Business Logic** - Age calculations, consent workflows, participation rules
3. **Service Layer** - ParticipationService functionality
4. **Edge Cases** - Age restrictions, consent expiration, rule evaluation

## Test Data

Factories are provided for all models with various traits:
- Users: adult, minor, child, teen, suspended
- Organizations: different types, age restrictions, consent requirements
- Participation Rules: different rule types and conditions
- Parental Consents: granted, denied, expired

## Configuration

- Uses FactoryBot for test data generation
- Uses Shoulda Matchers for validation testing
- Uses Database Cleaner for test isolation
- Configured for Devise authentication testing