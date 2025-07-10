class OrganizationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization, only: [:show, :edit, :update, :destroy, :analytics, :members]
  before_action :ensure_admin_access, only: [:edit, :update, :destroy, :members]

  def index
    @organizations = current_user.organizations.includes(:memberships)
  end

  def show
    @membership = current_user.memberships.find_by(organization: @organization)
    @recent_activities = @organization.activity_logs.includes(:user).recent(7).limit(10)
  end

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(organization_params)

    if @organization.save
      @organization.memberships.create!(user: current_user, role: :admin)
      ActivityLog.log_activity(current_user, @organization, 'member_joined', { role: 'admin' })

      redirect_to @organization, notice: 'Organization created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @organization.update(organization_params)
      ActivityLog.log_activity(current_user, @organization, 'organization_updated')
      redirect_to @organization, notice: 'Organization updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @organization.destroy
    ActivityLog.log_activity(current_user, @organization, 'organization_deleted')
    redirect_to organizations_path, notice: 'Organization deleted successfully.'
  end

  def analytics
    @recent_activities = @organization.activity_logs.includes(:user).recent(7).limit(10)
  end

  def members
    @memberships = @organization.memberships.includes(:user).order(:role, 'users.first_name')
  end

  private

  def set_organization
    @organization = current_user.organizations.find(params[:id])
  end

  def ensure_admin_access
    membership = current_user.memberships.find_by(organization: @organization)
    unless membership&.role == 'admin'
      redirect_to @organization, alert: 'You do not have permission to perform this action.'
    end
  end

  def organization_params
    params.require(:organization).permit(:name, :org_type, settings: {})
  end
end
