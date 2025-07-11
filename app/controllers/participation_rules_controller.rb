class ParticipationRulesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization
  before_action :ensure_admin_access
  before_action :set_rule, only: [ :show, :edit, :update, :destroy ]

  def index
    @rules = @organization.participation_rules.active.by_priority
  end

  def show
  end

  def new
    @rule = @organization.participation_rules.build
  end

  def create
    @rule = @organization.participation_rules.build(rule_params)

    if @rule.save
      ActivityLog.log_activity(current_user, @organization, "rule_created", { rule_type: @rule.rule_type })
      redirect_to organization_participation_rules_path(@organization), notice: "Rule created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @rule.update(rule_params)
      ActivityLog.log_activity(current_user, @organization, "rule_updated", { rule_type: @rule.rule_type })
      redirect_to organization_participation_rules_path(@organization), notice: "Rule updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    rule_type = @rule.rule_type
    @rule.destroy
    ActivityLog.log_activity(current_user, @organization, "rule_deleted", { rule_type: rule_type })

    redirect_to organization_participation_rules_path(@organization), notice: "Rule deleted successfully."
  end

  def test
    @user = User.find(params[:user_id])
    @rules = @organization.participation_rules.active.by_priority

    @results = @rules.map do |rule|
      {
        rule: rule,
        allowed: rule.evaluate(@user, params[:context] || {}),
        conditions: rule.conditions
      }
    end
  end

  private

  def set_organization
    @organization = current_user.organizations.find(params[:organization_id])
  end

  def set_rule
    @rule = @organization.participation_rules.find(params[:id])
  end

  def ensure_admin_access
    membership = current_user.memberships.find_by(organization: @organization)
    unless membership&.role == "admin"
      redirect_to @organization, alert: "You do not have permission to manage rules."
    end
  end

  def rule_params
    params.require(:participation_rule).permit(
      :rule_type, :description, :active, :priority,
      conditions: [ :allowed_roles, :minimum_age, :maximum_age, :required_consent ],
      actions: {}
    )
  end
end
