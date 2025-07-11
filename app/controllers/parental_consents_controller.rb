class ParentalConsentsController < ApplicationController
  before_action :set_consent, only: [ :show, :grant, :deny ]
  skip_before_action :authenticate_user!, only: [ :show, :grant, :deny ]

  def new
    @user = current_user
    @consent = ParentalConsent.new
  end

  def create
    @user = current_user
    @consent = @user.build_parental_consent(consent_params)

    if @consent.save
      ActivityLog.log_activity(@user, @user.organizations.first, "consent_requested", { parent_email: @consent.parent_email })

      redirect_to root_path, notice: "Parental consent request created. Consent token: " + @consent.consent_token
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    if @consent.expired?
      render :expired
    elsif @consent.consented?
      render :already_consented
    end
  end

  def grant
    if @consent.expired?
      redirect_to parental_consent_path(@consent), alert: "This consent request has expired."
      return
    end

    @consent.grant_consent!
    ActivityLog.log_activity(@consent.user, @consent.user.organizations.first, "consent_granted")

    redirect_to parental_consent_path(@consent), notice: "Consent granted successfully. The user can now participate."
  end

  def deny
    if @consent.expired?
      redirect_to parental_consent_path(@consent), alert: "This consent request has expired."
      return
    end

    @consent.update!(consented: false, notes: params[:notes])
    ActivityLog.log_activity(@consent.user, @consent.user.organizations.first, "consent_denied", { notes: params[:notes] })

    redirect_to parental_consent_path(@consent), notice: "Consent denied. The user will be notified."
  end

  private

  def set_consent
    @consent = ParentalConsent.find_by_token(params[:id])
    unless @consent
      redirect_to root_path, alert: "Invalid consent request."
    end
  end

  def consent_params
    params.require(:parental_consent).permit(:parent_email)
  end
end
