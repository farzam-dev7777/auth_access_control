require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:date_of_birth) }
  end

  describe 'associations' do
    it { should have_many(:memberships) }
    it { should have_many(:organizations).through(:memberships) }
    it { should have_one(:parental_consent).dependent(:destroy) }
  end

  describe 'scopes' do
    let!(:adult_user) { create(:user, :adult) }
    let!(:minor_user) { create(:user, :minor) }

    describe '.adults' do
      it 'returns only adult users' do
        expect(User.adults).to include(adult_user)
        expect(User.adults).not_to include(minor_user)
      end
    end

    describe '.minors' do
      it 'returns only minor users' do
        expect(User.minors).to include(minor_user)
        expect(User.minors).not_to include(adult_user)
      end
    end
  end

  describe '#age' do
    let(:user) { build(:user, date_of_birth: 20.years.ago) }

    it 'calculates age correctly' do
      expect(user.age).to eq(20)
    end

    it 'returns nil if date_of_birth is nil' do
      user.date_of_birth = nil
      expect(user.age).to be_nil
    end
  end

  describe '#age_group' do
    context 'when user is a child' do
      let(:user) { build(:user, :child) }

      it 'returns :child' do
        expect(user.age_group).to eq(:child)
      end
    end

    context 'when user is a teen' do
      let(:user) { build(:user, :teen) }

      it 'returns :teen' do
        expect(user.age_group).to eq(:teen)
      end
    end

    context 'when user is an adult' do
      let(:user) { build(:user, :adult) }

      it 'returns :adult' do
        expect(user.age_group).to eq(:adult)
      end
    end
  end

  describe '#minor?' do
    context 'when user is under 18' do
      let(:user) { build(:user, :minor) }

      it 'returns true' do
        expect(user.minor?).to be true
      end
    end

    context 'when user is 18 or older' do
      let(:user) { build(:user, :adult) }

      it 'returns false' do
        expect(user.minor?).to be false
      end
    end
  end

  describe '#requires_parental_consent?' do
    context 'when user is under 13' do
      let(:user) { build(:user, :child) }

      it 'returns true' do
        expect(user.requires_parental_consent?).to be true
      end
    end

    context 'when user is 13 or older' do
      let(:user) { build(:user, :teen) }

      it 'returns false' do
        expect(user.requires_parental_consent?).to be false
      end
    end
  end

  describe '#has_valid_parental_consent?' do
    context 'when user does not require consent' do
      let(:user) { build(:user, :adult) }

      it 'returns true' do
        expect(user.has_valid_parental_consent?).to be true
      end
    end

    context 'when user requires consent and has valid consent' do
      let(:user) { create(:user, :child) }
      let!(:consent) { create(:parental_consent, :granted, user: user) }

      it 'returns true' do
        expect(user.has_valid_parental_consent?).to be true
      end
    end

    context 'when user requires consent but has no consent' do
      let(:user) { build(:user, :child) }

      it 'returns false' do
        expect(user.has_valid_parental_consent?).to be_falsy
      end
    end

    context 'when user requires consent but consent is expired' do
      let(:user) { create(:user, :child) }
      let!(:consent) { create(:parental_consent, :granted, user: user) }

      before do
        consent.update!(expires_at: 1.day.ago)
      end

      it 'returns false' do
        expect(user.has_valid_parental_consent?).to be false
      end
    end
  end

  describe '#can_participate_in_organization?' do
    let(:user) { create(:user, :adult) }
    let(:organization) { create(:organization) }
    let!(:membership) { create(:membership, user: user, organization: organization) }

    context 'when user is a member and not suspended' do
      it 'returns true' do
        expect(user.can_participate_in_organization?(organization)).to be true
      end
    end

    context 'when user is suspended' do
      before { user.suspend! }

      it 'returns false' do
        expect(user.can_participate_in_organization?(organization)).to be false
      end
    end

    context 'when user is not a member' do
      let(:other_organization) { create(:organization) }

      it 'returns false' do
        expect(user.can_participate_in_organization?(other_organization)).to be false
      end
    end

    context 'when user is a minor without consent' do
      let(:minor_user) { create(:user, :child) }
      let!(:minor_membership) { create(:membership, user: minor_user, organization: organization) }

      it 'returns false' do
        expect(minor_user.can_participate_in_organization?(organization)).to be false
      end
    end
  end

  describe '#suspend!' do
    let(:user) { create(:user) }

    it 'suspends the user' do
      user.suspend!('Test reason')
      expect(user.suspended?).to be true
      expect(user.suspended_reason).to eq('Test reason')
    end
  end

  describe '#unsuspend!' do
    let(:user) { create(:user, :suspended) }

    it 'unsuspends the user' do
      user.unsuspend!
      expect(user.suspended?).to be false
      expect(user.suspended_reason).to be_nil
    end
  end

  describe 'personal organization creation' do
    context 'when skip_personal_organization is true' do
      it 'does not create a personal organization' do
        expect {
          create(:user, skip_personal_organization: true)
        }.not_to change(Organization, :count)
      end
    end

    context 'when skip_personal_organization is false' do
      it 'creates a personal organization' do
        expect {
          create(:user, :with_personal_organization)
        }.to change(Organization, :count).by(1)
      end

      it 'creates the user as admin of their personal organization' do
        user = create(:user, :with_personal_organization)
        organization = user.organizations.first

        expect(organization).to be_present
        expect(organization.name).to include(user.first_name)
        expect(organization.name).to include(user.last_name)
        expect(user.memberships.find_by(organization: organization).role).to eq('admin')
      end
    end

    context 'when skip_personal_organization is not set (default behavior)' do
      it 'does not create a personal organization (factory default)' do
        expect {
          create(:user)
        }.not_to change(Organization, :count)
      end
    end
  end

  describe 'validations' do
    context 'minimum age requirement' do
      it 'allows users 13 and older' do
        user = build(:user, date_of_birth: 13.years.ago)
        expect(user).to be_valid
      end

      it 'rejects users under 13' do
        user = build(:user, date_of_birth: 12.years.ago)
        expect(user).not_to be_valid
        expect(user.errors[:date_of_birth]).to include("You must be at least 13 years old to register.")
      end
    end
  end
end
