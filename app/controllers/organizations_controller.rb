require "csv"

class OrganizationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization, only: [ :show, :edit, :update, :destroy, :analytics, :members, :export_analytics, :generate_report ]
  before_action :ensure_admin_access, only: [ :edit, :update, :destroy, :members ]

  def index
    @organizations = current_user.organizations.includes(:memberships) if user_signed_in?
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
    authorize @organization
    if @organization.save
      @organization.memberships.create!(user: current_user, role: :admin)
      ActivityLog.log_activity(current_user, @organization, "organization_created", {
        org_type: @organization.org_type,
        allow_minors: @organization.allow_minors,
        requires_parental_consent: @organization.requires_parental_consent
      })
      redirect_to @organization, notice: "Organization created successfully! You can now manage members and configure settings."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @organization, :manage?
  end

  def update
    authorize @organization, :manage?
    if @organization.update(organization_params)
      ActivityLog.log_activity(current_user, @organization, "organization_updated", {
        changes: @organization.previous_changes.except("updated_at")
      })
      redirect_to @organization, notice: "Organization updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @organization, :manage?
    @organization.destroy
    ActivityLog.log_activity(current_user, @organization, "organization_deleted")
    redirect_to organizations_path, notice: "Organization deleted successfully."
  end

  def analytics
    authorize @organization, :analytics?
    @recent_activities = @organization.activity_logs.includes(:user).recent(7).limit(20)
  end

  def export_analytics
    authorize @organization, :export_analytics?
    csv_data = CSV.generate(headers: true) do |csv|
      csv << [ "Member Name", "Email", "Role", "Age", "Joined At" ]
      @organization.memberships.includes(:user).each do |membership|
        user = membership.user
        csv << [ user.full_name, user.email, membership.role, user.age, membership.created_at.strftime("%Y-%m-%d") ]
      end
    end
    send_data csv_data, filename: "#{@organization.name.parameterize}-analytics.csv"
  end

  def generate_report
    authorize @organization, :generate_report?
    require "prawn"
    pdf = Prawn::Document.new
    pdf.text "Organization Report: #{@organization.name}", size: 20, style: :bold
    pdf.move_down 10
    pdf.text "Total Members: #{@organization.active_members_count}"
    pdf.text "Admins: #{@organization.memberships.where(role: 'admin').count}"
    pdf.text "Active Rules: #{@organization.participation_rules.where(active: true).count}"
    pdf.move_down 10
    pdf.text "Members List:", style: :bold
    @organization.memberships.includes(:user).each do |membership|
      user = membership.user
      pdf.text "- #{user.full_name} (#{membership.role.humanize}, Age: #{user.age})"
    end
    send_data pdf.render, filename: "#{@organization.name.parameterize}-report.pdf", type: "application/pdf"
  end

  def members
    authorize @organization, :manage?
    @memberships = @organization.memberships.includes(:user).order(:role, "users.first_name")
  end

  private

  def set_organization
    @organization = Organization.find(params[:id])
  end

  def ensure_admin_access
    membership = current_user.memberships.find_by(organization: @organization)
    unless membership&.role == "admin"
      redirect_to @organization, alert: "You do not have permission to perform this action."
    end
  end

  def organization_params
    params_hash = params.require(:organization).permit(:name, :org_type, :min_age, :max_age, :allow_minors, :requires_parental_consent)
    settings = {}
    settings["min_age"] = params_hash[:min_age].to_i if params_hash[:min_age].present?
    settings["max_age"] = params_hash[:max_age].to_i if params_hash[:max_age].present?
    settings["allow_minors"] = params_hash[:allow_minors] == "1" || params_hash[:allow_minors] == true
    settings["requires_parental_consent"] = params_hash[:requires_parental_consent] == "1" || params_hash[:requires_parental_consent] == true
    {
      name: params_hash[:name],
      org_type: params_hash[:org_type],
      settings: settings
    }
  end
end
