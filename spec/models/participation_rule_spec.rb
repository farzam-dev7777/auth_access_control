require 'rails_helper'

RSpec.describe ParticipationRule, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:rule_type) }
    it { should validate_numericality_of(:priority).is_greater_than_or_equal_to(0) }
  end

  describe 'associations' do
    it { should belong_to(:organization) }
  end

  describe 'scopes' do
    let!(:active_rule) { create(:participation_rule, active: true) }
    let!(:inactive_rule) { create(:participation_rule, active: false) }

    describe '.active' do
      it 'returns only active rules' do
        expect(ParticipationRule.active).to include(active_rule)
        expect(ParticipationRule.active).not_to include(inactive_rule)
      end
    end

    describe '.by_priority' do
      let!(:low_priority_rule) { create(:participation_rule, priority: 1) }
      let!(:high_priority_rule) { create(:participation_rule, priority: 10) }

      it 'orders rules by priority descending' do
        rules = ParticipationRule.by_priority.limit(2)
        expect(rules.pluck(:priority)).to eq([ 10, 1 ])
      end
    end
  end

  describe 'constants' do
    it 'defines valid rule types' do
      expect(ParticipationRule::RULE_TYPES).to include(
        'event_creation',
        'content_posting',
        'member_invitation',
        'role_assignment',
        'content_access',
        'age_restriction'
      )
    end
  end

  describe '#evaluate' do
    let(:organization) { create(:organization) }
    let(:user) { create(:user, :adult) }
    let(:rule) { create(:participation_rule, organization: organization) }

    context 'when rule is inactive' do
      let(:rule) { create(:participation_rule, :inactive, organization: organization) }

      it 'returns false' do
        expect(rule.evaluate(user)).to be false
      end
    end

    context 'when rule is active' do
      describe 'event_creation rule' do
        context 'when user is a member with allowed role' do
          let!(:membership) { create(:membership, :admin, user: user, organization: organization) }
          let(:rule) { create(:participation_rule, :event_creation, organization: organization, conditions: { 'allowed_roles' => [ 'admin' ] }) }

          it 'returns true' do
            expect(rule.evaluate(user)).to be true
          end
        end

        context 'when user is not a member' do
          it 'returns false' do
            expect(rule.evaluate(user)).to be false
          end
        end

        context 'when user has non-allowed role' do
          let!(:membership) { create(:membership, :member, user: user, organization: organization) }

          it 'returns false' do
            expect(rule.evaluate(user)).to be false
          end
        end
      end

      describe 'content_posting rule' do
        context 'when user is a member with allowed role' do
          let!(:membership) { create(:membership, :admin, user: user, organization: organization) }
          let(:rule) { create(:participation_rule, :content_posting, organization: organization, conditions: { 'allowed_roles' => [ 'admin' ] }) }

          it 'returns true' do
            expect(rule.evaluate(user)).to be true
          end
        end

        context 'when user is not a member' do
          it 'returns false' do
            expect(rule.evaluate(user)).to be false
          end
        end
      end

      describe 'member_invitation rule' do
        let(:rule) { create(:participation_rule, :member_invitation, organization: organization) }

        context 'when user is an admin' do
          let!(:membership) { create(:membership, :admin, user: user, organization: organization) }

          it 'returns true' do
            expect(rule.evaluate(user)).to be true
          end
        end

        context 'when user is not an admin' do
          let!(:membership) { create(:membership, :member, user: user, organization: organization) }

          it 'returns false' do
            expect(rule.evaluate(user)).to be false
          end
        end

        context 'when user is not a member' do
          it 'returns false' do
            expect(rule.evaluate(user)).to be false
          end
        end
      end

      describe 'role_assignment rule' do
        let(:rule) { create(:participation_rule, :role_assignment, organization: organization) }

        context 'when user is an admin' do
          let!(:membership) { create(:membership, :admin, user: user, organization: organization) }

          it 'returns true' do
            expect(rule.evaluate(user)).to be true
          end
        end

        context 'when user is not an admin' do
          let!(:membership) { create(:membership, :member, user: user, organization: organization) }

          it 'returns false' do
            expect(rule.evaluate(user)).to be false
          end
        end
      end

      describe 'content_access rule' do
        let(:rule) { create(:participation_rule, :content_access, organization: organization) }
        let!(:membership) { create(:membership, user: user, organization: organization) }

        context 'when user meets age requirements' do
          it 'returns true' do
            expect(rule.evaluate(user)).to be true
          end
        end

        context 'when user is below minimum age' do
          let(:rule) { create(:participation_rule, :content_access, organization: organization, conditions: { 'minimum_age' => 20 }) }
          let(:young_user) { create(:user, date_of_birth: 18.years.ago) }
          let!(:young_membership) { create(:membership, user: young_user, organization: organization) }

          it 'returns false' do
            expect(rule.evaluate(young_user)).to be false
          end
        end

        context 'when user is above maximum age' do
          let(:rule) { create(:participation_rule, :content_access, organization: organization, conditions: { 'maximum_age' => 20 }) }
          let(:old_user) { create(:user, date_of_birth: 25.years.ago) }
          let!(:old_membership) { create(:membership, user: old_user, organization: organization) }

          it 'returns false' do
            expect(rule.evaluate(old_user)).to be false
          end
        end

        context 'when consent is required and user is a minor without consent' do
          let(:rule) { create(:participation_rule, :content_access, organization: organization, conditions: { 'required_consent' => true }) }
          let(:minor_user) { create(:user, :child) }
          let!(:minor_membership) { create(:membership, user: minor_user, organization: organization) }

          it 'returns false' do
            expect(rule.evaluate(minor_user)).to be false
          end
        end

        context 'when consent is required and user is a minor with consent' do
          let(:rule) { create(:participation_rule, :content_access, organization: organization, conditions: { 'required_consent' => true }) }
          let(:minor_user) { create(:user, :child) }
          let!(:minor_membership) { create(:membership, user: minor_user, organization: organization) }
          let!(:consent) { create(:parental_consent, :granted, user: minor_user) }

          it 'returns true' do
            expect(rule.evaluate(minor_user)).to be true
          end
        end
      end

      describe 'age_restriction rule' do
        let(:rule) { create(:participation_rule, :age_restriction, organization: organization) }

        context 'when user meets age requirements' do
          it 'returns true' do
            expect(rule.evaluate(user)).to be true
          end
        end

        context 'when user is below minimum age' do
          let(:rule) { create(:participation_rule, :age_restriction, organization: organization, conditions: { 'minimum_age' => 20 }) }
          let(:young_user) { create(:user, date_of_birth: 18.years.ago) }

          it 'returns false' do
            expect(rule.evaluate(young_user)).to be false
          end
        end

        context 'when user is above maximum age' do
          let(:rule) { create(:participation_rule, :age_restriction, organization: organization, conditions: { 'maximum_age' => 20 }) }
          let(:old_user) { create(:user, date_of_birth: 25.years.ago) }

          it 'returns false' do
            expect(rule.evaluate(old_user)).to be false
          end
        end
      end
    end
  end

  describe 'helper methods' do
    let(:rule) { create(:participation_rule) }

    describe '#allowed_roles' do
      it 'returns allowed roles from conditions' do
        rule.conditions = { 'allowed_roles' => [ 'admin', 'moderator' ] }
        expect(rule.allowed_roles).to eq([ 'admin', 'moderator' ])
      end

      it 'returns empty array when not set' do
        expect(rule.allowed_roles).to eq([])
      end
    end

    describe '#minimum_age' do
      it 'returns minimum age from conditions' do
        rule.conditions = { 'minimum_age' => 13 }
        expect(rule.minimum_age).to eq(13)
      end

      it 'returns nil when not set' do
        expect(rule.minimum_age).to be_nil
      end
    end

    describe '#maximum_age' do
      it 'returns maximum age from conditions' do
        rule.conditions = { 'maximum_age' => 25 }
        expect(rule.maximum_age).to eq(25)
      end

      it 'returns nil when not set' do
        expect(rule.maximum_age).to be_nil
      end
    end

    describe '#required_consent' do
      it 'returns required consent from conditions' do
        rule.conditions = { 'required_consent' => true }
        expect(rule.required_consent).to be true
      end

      it 'returns false when not set' do
        expect(rule.required_consent).to be false
      end
    end
  end
end
