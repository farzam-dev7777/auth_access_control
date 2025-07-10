require 'rails_helper'

RSpec.describe ParticipationService, type: :service do
  let(:user) { create(:user, :adult) }
  let(:organization) { create(:organization) }
  let(:service) { ParticipationService.new(user, organization) }

  describe '#initialize' do
    it 'sets user and organization' do
      expect(service.instance_variable_get(:@user)).to eq(user)
      expect(service.instance_variable_get(:@organization)).to eq(organization)
    end
  end

  describe '#can_perform_action?' do
    let!(:membership) { create(:membership, :admin, user: user, organization: organization) }

    context 'when user cannot participate in organization' do
      before do
        user.suspend!
      end

      it 'returns false' do
        expect(service.can_perform_action?('event_creation')).to be false
      end
    end

    context 'when user can participate in organization' do
      context 'when no rules exist for the action' do
        it 'returns true' do
          expect(service.can_perform_action?('event_creation')).to be true
        end
      end

      context 'when rules exist for the action' do
        let!(:rule) { create(:participation_rule, :event_creation, organization: organization, conditions: { 'allowed_roles' => ['admin'] }) }

        context 'when rule allows the action' do
          it 'returns true' do
            expect(service.can_perform_action?('event_creation')).to be true
          end
        end

        context 'when rule denies the action' do
          let!(:rule) { create(:participation_rule, :event_creation, organization: organization, conditions: { 'allowed_roles' => ['moderator'] }) }

          it 'returns false' do
            expect(service.can_perform_action?('event_creation')).to be false
          end
        end

        context 'when multiple rules exist' do
          let!(:rule2) { create(:participation_rule, :event_creation, organization: organization, priority: 2, conditions: { 'allowed_roles' => ['admin'] }) }

          context 'when first rule allows but second denies' do
            let!(:rule) { create(:participation_rule, :event_creation, organization: organization, conditions: { 'allowed_roles' => ['moderator'] }) }

            it 'returns false (denied by higher priority rule)' do
              expect(service.can_perform_action?('event_creation')).to be false
            end
          end

          context 'when both rules allow' do
            let!(:rule) { create(:participation_rule, :event_creation, organization: organization, conditions: { 'allowed_roles' => ['admin'] }) }

            it 'returns true' do
              expect(service.can_perform_action?('event_creation')).to be true
            end
          end
        end
      end
    end
  end

  describe '#check_age_restrictions' do
    context 'when user is not a minor' do
      it 'returns true' do
        expect(service.check_age_restrictions).to be true
      end
    end

    context 'when user is a minor' do
      let(:minor_user) { create(:user, :minor) }
      let(:service) { ParticipationService.new(minor_user, organization) }

      context 'when organization does not allow minors' do
        it 'returns false' do
          expect(service.check_age_restrictions).to be false
        end
      end

      context 'when organization allows minors' do
        let(:organization) { create(:organization, :allows_minors) }

        context 'when organization has minimum age restriction' do
          let(:organization) { create(:organization, :allows_minors, settings: { 'min_age' => 15 }) }
          let(:young_minor) { create(:user, date_of_birth: 13.years.ago) }
          let(:service) { ParticipationService.new(young_minor, organization) }

          it 'returns false when user is below minimum age' do
            expect(service.check_age_restrictions).to be false
          end
        end

        context 'when organization has maximum age restriction' do
          let(:organization) { create(:organization, :allows_minors, settings: { 'max_age' => 15 }) }
          let(:old_minor) { create(:user, date_of_birth: 17.years.ago) }
          let(:service) { ParticipationService.new(old_minor, organization) }

          it 'returns false when user is above maximum age' do
            expect(service.check_age_restrictions).to be false
          end
        end
      end
    end
  end

  describe '#get_participation_status' do
    let!(:membership) { create(:membership, user: user, organization: organization) }

    it 'returns a hash with participation status information' do
      status = service.get_participation_status

      expect(status).to include(
        :can_participate,
        :age_restrictions_passed,
        :membership_status,
        :consent_status
      )
    end

    it 'calls can_participate_in_organization?' do
      expect(user).to receive(:can_participate_in_organization?).with(organization)
      service.get_participation_status
    end

    it 'calls check_age_restrictions' do
      expect(service).to receive(:check_age_restrictions)
      service.get_participation_status
    end
  end

  describe '#log_activity' do
    it 'calls ActivityLog.log_activity with correct parameters' do
      metadata = { test: 'data' }
      expected_metadata = metadata.merge(ip_address: 'unknown', user_agent: 'unknown')
      expect(ActivityLog).to receive(:log_activity).with(user, organization, 'test_action', expected_metadata)
      service.log_activity('test_action', metadata)
    end

    it 'includes default metadata when none provided' do
      expected_metadata = { ip_address: 'unknown', user_agent: 'unknown' }
      expect(ActivityLog).to receive(:log_activity).with(user, organization, 'test_action', expected_metadata)
      service.log_activity('test_action')
    end
  end

  describe 'private methods' do
    describe '#get_membership_status' do
      context 'when user has membership' do
        let!(:membership) { create(:membership, :admin, user: user, organization: organization) }

        it 'returns membership information' do
          status = service.send(:get_membership_status)
          expect(status).to include(
            role: 'admin',
            joined_at: membership.created_at
          )
        end
      end

      context 'when user does not have membership' do
        it 'returns not_member' do
          expect(service.send(:get_membership_status)).to eq('not_member')
        end
      end
    end

    describe '#get_consent_status' do
      context 'when user does not require consent' do
        it 'returns not_required' do
          expect(service.send(:get_consent_status)).to eq('not_required')
        end
      end

      context 'when user requires consent' do
        let(:minor_user) { create(:user, :child) }
        let(:service) { ParticipationService.new(minor_user, organization) }

        context 'when user has valid consent' do
          let!(:consent) { create(:parental_consent, :granted, user: minor_user) }

          it 'returns granted' do
            expect(service.send(:get_consent_status)).to eq('granted')
          end
        end

        context 'when user has no consent' do
          it 'returns pending' do
            expect(service.send(:get_consent_status)).to eq('pending')
          end
        end

        context 'when user has expired consent' do
          let!(:consent) { create(:parental_consent, :granted, user: minor_user) }

          before do
            consent.update!(expires_at: 1.day.ago)
          end

          it 'returns expired' do
            expect(service.send(:get_consent_status)).to eq('expired')
          end
        end
      end
    end
  end
end