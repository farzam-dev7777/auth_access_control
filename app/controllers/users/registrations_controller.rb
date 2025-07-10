class Users::RegistrationsController < Devise::RegistrationsController
  def new
    build_resource({})
  end

  def create
    org_attrs = params.dig(:user, :organization)
    build_resource(sign_up_params.except(:organization))

    ActiveRecord::Base.transaction do
      if org_attrs.present?
        org = Organization.create!(org_attrs.permit(:name, :org_type))
        resource.save!
        Membership.create!(user: resource, organization: org, role: :admin)

        # Handle parental consent for minors
        if resource.requires_parental_consent?
          redirect_to new_parental_consent_path, notice: 'Registration successful! Parental consent is required to continue.'
          return
        end
      else
        resource.errors.add(:base, "Organization must be provided")
        render :new and return
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

end
