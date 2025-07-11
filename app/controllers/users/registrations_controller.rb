class Users::RegistrationsController < Devise::RegistrationsController
  def new
    build_resource({})
  end

  def create
    org_attrs = params.dig(:user, :organization)
    build_resource(sign_up_params.except(:organization))

    ActiveRecord::Base.transaction do
      resource.save!

      # Create organization only if both fields are present and not blank
      if org_attrs.present? && org_attrs[:name].present? && org_attrs[:org_type].present?
        org = Organization.create!(org_attrs.permit(:name, :org_type))
        Membership.create!(user: resource, organization: org, role: :admin)
      end

      # Handle parental consent for minors
      if resource.requires_parental_consent?
        redirect_to new_parental_consent_path, notice: 'Registration successful! Parental consent is required to continue.'
        return
      end
    end

    if resource.persisted?
      sign_up(resource_name, resource)
      respond_with resource, location: after_sign_up_path_for(resource)
    else
      render :new
    end
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = e.message
    render :new
  end

  private

  def sign_up_params
    params.require(:user).permit(
      :first_name, :last_name, :email, :date_of_birth, :password, :password_confirmation,
      organization: [:name, :org_type]
    )
  end

end
