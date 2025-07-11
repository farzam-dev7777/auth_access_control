class Users::RegistrationsController < Devise::RegistrationsController
  def new
    build_resource({})
  end

  def create
    build_resource(sign_up_params)

    if resource.save && resource.persisted?
      sign_up(resource_name, resource)

      if resource.requires_parental_consent?
        # Redirect under-13 users directly to parental consent form
        redirect_to new_parental_consent_path, notice: "Registration successful! Please complete parental consent to continue."
      else
        # Adults go to normal after_sign_up path
        respond_with resource, location: after_sign_up_path_for(resource)
      end
    else
      flash[:alert] = resource.errors.full_messages.to_sentence
      render :new
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(
      :first_name, :last_name, :email, :date_of_birth, :password, :password_confirmation
    )
  end
end
