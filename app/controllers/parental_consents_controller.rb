class ParentalConsentsController < ApplicationController
  before_action :set_consent, only: [ :show, :grant, :deny ]
  skip_before_action :authenticate_user!, only: [ :show, :grant, :deny ]

  def index
    unless current_user.memberships.first&.role == "admin"
      return redirect_to root_path, alert: "Admin access required."
    end
    @consents = ParentalConsent.all.order(created_at: :desc)
  end

  def new
    @user = current_user

    # Check if user already has valid parental consent
    if @user.has_valid_parental_consent?
      redirect_to root_path, notice: "You already have valid parental consent. You can now access the platform."
      return
    end

    # Check if user already has a pending consent request
    if @user.parental_consent&.pending?
      redirect_to root_path, notice: "You already have a pending parental consent request. Please wait for your parent or guardian to respond."
      return
    end

    @consent = ParentalConsent.new
  end

  def create
    @user = current_user
    @consent = @user.build_parental_consent(consent_params)

    # Validate organization selection
    organization = Organization.find(params[:organization_id])
    unless organization.can_user_join?(@user)
      @consent.errors.add(:base, "You are not eligible to join the selected organization.")
      return render :new, status: :unprocessable_entity
    end

    if @consent.save
      # Check if membership request already exists
      existing_request = @user.membership_requests.find_by(organization: organization)

      unless existing_request
        # Create new membership request
        MembershipRequest.create!(
          user: @user,
          organization: organization,
          message: "Requesting membership as part of parental consent process"
        )
      end

      # Send email to parent/guardian
      ParentalConsentMailer.consent_request(@consent).deliver_now

      # Log activity with organization validation
      organization_for_log = organization.present? ? organization : nil
      ActivityLog.log_activity(@user, organization_for_log, "consent_requested", {
        parent_email: @consent.parent_email,
        organization_id: params[:organization_id]
      })

      redirect_to root_path, notice: "Parental consent request created and email sent to #{@consent.parent_email}. Consent token: " + @consent.consent_token
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @organization = @consent.user.organizations.first

    # Log consent view activity - use anonymous user if not signed in
    user_for_log = user_signed_in? ? current_user : nil
    organization_for_log = @consent.organization.present? ? @consent.organization : nil
    ActivityLog.log_activity(user_for_log, organization_for_log, "consent_viewed", {
      parent_email: @consent.parent_email,
      child_user_id: @consent.user.id,
      consent_status: @consent.consented? ? 'consented' : 'pending'
    })

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


    # Log activity if there was a membership request (regardless of approval success)
    user_for_log = user_signed_in? ? current_user : nil
    organization_for_log = user_signed_in? ? current_user.organizations.first : nil
    ActivityLog.log_activity(user_for_log, organization_for_log, "consent_granted", {
      parent_email: @consent.parent_email,
      child_user_id: @consent.user.id,
      membership_approved: organization_granted
    })

    redirect_to parental_consent_path(@consent), notice: "Consent granted successfully. The user can now participate."
  end

  def deny
    if @consent.expired?
      redirect_to parental_consent_path(@consent.consent_token), alert: "This consent request has expired."
      return
    end

    @consent.update!(consented: false, notes: params[:notes])

    # Check if there was a membership request to reject
    membership_request = @consent.user.membership_requests.pending.first
    organization_rejected = false

    if membership_request
      begin
        membership_request.reject!
        organization_rejected = true
      rescue => e
        Rails.logger.error "Failed to reject membership request: #{e.message}"
      end
    end

    # Log activity if there was a membership request (regardless of rejection success)
    if membership_request
      user_for_log = user_signed_in? ? current_user : nil
      organization_for_log = membership_request.organization
      ActivityLog.log_activity(user_for_log, organization_for_log, "consent_denied", {
        notes: params[:notes],
        parent_email: @consent.parent_email,
        child_user_id: @consent.user.id,
        membership_rejected: organization_rejected
      })
    end

    redirect_to parental_consent_path(@consent.consent_token), notice: "Consent denied. The user will be notified."
  end

  private

  def set_consent
    @consent = ParentalConsent.find_by_token(params[:id])

    redirect_to root_path, alert: "Invalid consent request." unless @consent
  end

  def consent_params
    params.require(:parental_consent).permit(:parent_email)
  end
end
