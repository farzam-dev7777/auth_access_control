class ParentalConsentMailer < ApplicationMailer
  def consent_request(parental_consent)
    @parental_consent = parental_consent
    @user = parental_consent.user
    @organization = parental_consent.organization
    @consent_url = parental_consent_url(@parental_consent.consent_token)

    mail(
      to: @parental_consent.parent_email,
      subject: "Parental Consent Required for #{@user.full_name}'s Account"
    )
  end
end