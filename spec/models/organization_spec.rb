require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:org_type) }
    it { should validate_uniqueness_of(:name) }
  end

  describe 'associations' do
    it { should have_many(:memberships) }
    it { should have_many(:users).through(:memberships) }
    it { should have_many(:participation_rules).dependent(:destroy) }
    it { should have_many(:activity_logs).dependent(:destroy) }
  end

  describe 'enums' do
    it { should define_enum_for(:org_type).with_values(educational: 0, nonprofit: 1, corporate: 2, community: 3) }
  end

  describe 'scopes' do
    let!(:org_allowing_minors) { create(:organization, :allows_minors) }
    let!(:org_not_allowing_minors) { create(:organization) }

    describe '.allowing_minors' do
      it 'returns only organizations that allow minors' do
        expect(Organization.allowing_minors).to include(org_allowing_minors)
        expect(Organization.allowing_minors).not_to include(org_not_allowing_minors)
      end
    end
  end

  describe '#admins' do
    let(:organization) { create(:organization) }
    let(:admin_user) { create(:user) }
    let(:member_user) { create(:user) }

    before do
      create(:membership, :admin, user: admin_user, organization: organization)
      create(:membership, :member, user: member_user, organization: organization)
    end

    it 'returns only admin users' do
      expect(organization.admins).to include(admin_user)
      expect(organization.admins).not_to include(member_user)
    end
  end

  describe '#can_user_join?' do
    let(:organization) { create(:organization) }
    let(:adult_user) { create(:user, :adult) }
    let(:minor_user) { create(:user, :minor) }

    context 'when organization allows minors' do
      let(:organization) { create(:organization, :allows_minors) }

      it 'allows adult users to join' do
        expect(organization.can_user_join?(adult_user)).to be true
      end

      it 'allows minor users to join' do
        expect(organization.can_user_join?(minor_user)).to be true
      end
    end

    context 'when organization does not allow minors' do
      it 'allows adult users to join' do
        expect(organization.can_user_join?(adult_user)).to be true
      end

      it 'prevents minor users from joining' do
        expect(organization.can_user_join?(minor_user)).to be false
      end
    end

    context 'when organization has age restrictions' do
      let(:organization) { create(:organization, :with_age_restrictions) }
      let(:teen_user) { create(:user, :teen) }
      let(:older_user) { create(:user, date_of_birth: 30.years.ago) }

      it 'allows users within age range' do
        expect(organization.can_user_join?(teen_user)).to be true
      end

      it 'prevents users outside age range' do
        expect(organization.can_user_join?(older_user)).to be false
      end
    end
  end

  describe '#active_members_count' do
    let(:organization) { create(:organization) }
    let!(:membership1) { create(:membership, organization: organization) }
    let!(:membership2) { create(:membership, organization: organization) }

    it 'returns the count of active members' do
      expect(organization.active_members_count).to eq(2)
    end
  end

  describe 'settings methods' do
    let(:organization) { create(:organization) }

    describe '#min_age' do
      it 'returns min_age from settings' do
        organization.settings = { 'min_age' => 13 }
        expect(organization.min_age).to eq(13)
      end

      it 'returns nil when min_age is not set' do
        expect(organization.min_age).to be_nil
      end
    end

    describe '#max_age' do
      it 'returns max_age from settings' do
        organization.settings = { 'max_age' => 25 }
        expect(organization.max_age).to eq(25)
      end

      it 'returns nil when max_age is not set' do
        expect(organization.max_age).to be_nil
      end
    end

    describe '#allow_minors' do
      it 'returns true when allow_minors is true' do
        organization.settings = { 'allow_minors' => true }
        expect(organization.allow_minors).to be true
      end

      it 'returns true when allow_minors is "true"' do
        organization.settings = { 'allow_minors' => 'true' }
        expect(organization.allow_minors).to be true
      end

      it 'returns false when allow_minors is not set' do
        expect(organization.allow_minors).to be false
      end
    end

    describe '#requires_parental_consent' do
      it 'returns true when requires_parental_consent is true' do
        organization.settings = { 'requires_parental_consent' => true }
        expect(organization.requires_parental_consent).to be true
      end

      it 'returns true when requires_parental_consent is "true"' do
        organization.settings = { 'requires_parental_consent' => 'true' }
        expect(organization.requires_parental_consent).to be true
      end

      it 'returns false when requires_parental_consent is not set' do
        expect(organization.requires_parental_consent).to be false
      end
    end
  end
end