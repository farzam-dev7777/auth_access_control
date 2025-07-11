class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!
  before_action :check_parental_consent_requirement

  include Pundit::Authorization
  include AccessControl

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def configure_permitted_parameters
    added_attrs = %i[first_name last_name date_of_birth email password password_confirmation]
    devise_parameter_sanitizer.permit(:sign_up, keys: added_attrs)
    devise_parameter_sanitizer.permit(:account_update, keys: added_attrs)
  end

  private

  def check_parental_consent_requirement
    return unless user_signed_in?
    return unless current_user.requires_parental_consent?
    return if current_user.has_valid_parental_consent?
    return if controller_name == 'parental_consents'
    return if controller_name == 'devise/sessions' && action_name == 'destroy'

    redirect_to new_parental_consent_path, alert: "Parental consent is required before you can access this feature."
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end
end
