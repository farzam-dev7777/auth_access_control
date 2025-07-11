class MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization
  before_action :set_membership, only: [ :update, :destroy ]
  before_action :ensure_admin_access

  def create
    user = User.find_by(email: params[:email])
    new_user = false

    unless user
      password = Devise.friendly_token.first(12)
      user = User.new(
        email: params[:email],
        password: password,
        password_confirmation: password,
        first_name: params[:first_name].presence || "Invited",
        last_name: params[:last_name].presence || "User",
        date_of_birth: params[:date_of_birth].presence || 13.years.ago
      )
      user.save!
      new_user = true
    end

    membership = @organization.memberships.new(user: user, role: params[:role])
    if membership.save
      if new_user
        token = user.send_reset_password_instructions
        UserInviteMailer.invite(user, @organization, current_user, token).deliver_later
        flash[:notice] = "Member added and invitation sent to #{user.email}."
      else
        flash[:notice] = "Member added successfully."
      end
    else
      flash[:alert] = "Failed to add member: #{membership.errors.full_messages.to_sentence}"
    end
    redirect_to members_organization_path(@organization)
  end

  def update
    if @membership.update(membership_params)
      ActivityLog.log_activity(current_user, @organization, "role_changed", {
        user_id: @membership.user_id,
        new_role: @membership.role,
        previous_role: @membership.role_previously_was
      })
      redirect_to members_organization_path(@organization), notice: "Member role updated successfully."
    else
      redirect_to members_organization_path(@organization), alert: "Failed to update member role."
    end
  end

  def destroy
    user_name = @membership.user.full_name
    @membership.destroy
    ActivityLog.log_activity(current_user, @organization, "member_removed", {
      user_id: @membership.user_id,
      user_name: user_name
    })
    redirect_to members_organization_path(@organization), notice: "#{user_name} has been removed from the organization."
  end

  private

  def set_organization
    @organization = current_user.organizations.find(params[:organization_id])
  end

  def set_membership
    @membership = @organization.memberships.find(params[:id])
  end

  def ensure_admin_access
    membership = current_user.memberships.find_by(organization: @organization)
    unless membership&.role == "admin"
      redirect_to @organization, alert: "You do not have permission to manage members."
    end
  end

  def membership_params
    params.require(:membership).permit(:role)
  end
end
