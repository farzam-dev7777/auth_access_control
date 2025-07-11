class ParticipationService
  def initialize(user, organization)
    @user = user
    @organization = organization
  end

  def can_perform_action?(action, context = {})
    return false unless @user.can_participate_in_organization?(@organization)

    rules = @organization.participation_rules.active.by_priority
    rules.each do |rule|
      next unless rule.rule_type == action

      unless rule.evaluate(@user, context)
        return false
      end
    end

    true
  end

  def check_age_restrictions
    return true unless @user.minor?
    return false if @organization.min_age && @user.age < @organization.min_age
    return false if @organization.max_age && @user.age > @organization.max_age
    false unless @organization.allow_minors
  end

  def get_accessible_content(content_type = nil)
    return [] unless @user.memberships.exists?(organization: @organization)

    if @user.minor?
      # Filter content based on age appropriateness
      []
    end
    # Return all content for adults
  end

  def log_activity(action, metadata = {})
    ActivityLog.log_activity(
      @user,
      @organization,
      action,
      metadata.merge(
        ip_address: metadata[:ip_address] || "unknown",
        user_agent: metadata[:user_agent] || "unknown"
      )
    )
  end

  def get_participation_status
    {
      can_participate: @user.can_participate_in_organization?(@organization),
      age_restrictions_passed: check_age_restrictions,
      membership_status: get_membership_status,
      consent_status: get_consent_status
    }
  end

  private

  def get_membership_status
    membership = @user.memberships.find_by(organization: @organization)
    return "not_member" unless membership

    {
      role: membership.role,
      joined_at: membership.created_at,
      active: true
    }
  end

  def get_consent_status
    return "not_required" unless @user.requires_parental_consent?

    if @user.has_valid_parental_consent?
      "granted"
    elsif @user.parental_consent&.expired?
      "expired"
    else
      "pending"
    end
  end
end
