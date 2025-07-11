class MembershipRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization, only: [ :create ]
  before_action :set_membership_request, only: [ :approve, :reject, :destroy ]
  before_action :ensure_admin_access, only: [ :approve, :reject ]

  def create
    # Check if user already has a membership or pending request
    if @organization.memberships.exists?(user: current_user)
      flash[:alert] = "You are already a member of this organization."
      redirect_to organization_path(@organization) and return
    end

    if @organization.membership_requests.exists?(user: current_user, status: "pending")
      flash[:alert] = "You already have a pending request to join this organization."
      redirect_to organization_path(@organization) and return
    end

    # Check age restrictions
    unless @organization.can_user_join?(current_user)
      flash[:alert] = "You do not meet the age requirements for this organization."
      redirect_to organization_path(@organization) and return
    end

    membership_request = @organization.membership_requests.new(
      user: current_user,
      message: params[:message]
    )

    if membership_request.save
      ActivityLog.log_activity(current_user, @organization, "membership_requested", {
        user_id: current_user.id,
        message: params[:message]
      })
      flash[:notice] = "Your request to join has been submitted and is pending approval."
    else
      flash[:alert] = "Failed to submit request: #{membership_request.errors.full_messages.to_sentence}"
    end

    redirect_to organization_path(@organization)
  end

  def approve
    if @membership_request.approve!
      ActivityLog.log_activity(current_user, @membership_request.organization, "membership_approved", {
        user_id: @membership_request.user_id,
        approved_by: current_user.id
      })
      flash[:notice] = "#{@membership_request.user.full_name} has been approved to join the organization."
    else
      flash[:alert] = "Failed to approve membership request."
    end

    redirect_to members_organization_path(@membership_request.organization)
  end

  def reject
    if @membership_request.reject!
      ActivityLog.log_activity(current_user, @membership_request.organization, "membership_rejected", {
        user_id: @membership_request.user_id,
        rejected_by: current_user.id
      })
      flash[:notice] = "#{@membership_request.user.full_name}'s request has been rejected."
    else
      flash[:alert] = "Failed to reject membership request."
    end

    redirect_to members_organization_path(@membership_request.organization)
  end

  def destroy
    if @membership_request.user == current_user
      @membership_request.destroy
      flash[:notice] = "Your membership request has been cancelled."
      redirect_to organizations_path
    else
      flash[:alert] = "You can only cancel your own requests."
      redirect_to organization_path(@membership_request.organization)
    end
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_membership_request
    @membership_request = MembershipRequest.find(params[:id])
  end

  def ensure_admin_access
    membership = current_user.memberships.find_by(organization: @membership_request.organization)
    unless membership&.role == "admin"
      redirect_to @membership_request.organization, alert: "You do not have permission to manage membership requests."
    end
  end
end
