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

    # Check content_access rules first
    unless can_perform_action?('content_access')
      return []
    end

    # Demo content - in a real app, this would come from a database
    demo_content = {
      child: [
        { id: 1, title: "Educational Games", type: "educational", age_rating: "all_ages" },
        { id: 2, title: "Safety Guidelines", type: "guidelines", age_rating: "all_ages" },
        { id: 3, title: "Parent-Approved Activities", type: "activities", age_rating: "child_safe" }
      ],
      teen: [
        { id: 4, title: "Study Resources", type: "educational", age_rating: "teen" },
        { id: 5, title: "Community Guidelines", type: "guidelines", age_rating: "teen" },
        { id: 6, title: "Youth Programs", type: "programs", age_rating: "teen" },
        { id: 7, title: "Leadership Opportunities", type: "opportunities", age_rating: "teen" }
      ],
      adult: [
        { id: 8, title: "General Content", type: "general", age_rating: "adult" },
        { id: 9, title: "Advanced Features", type: "advanced", age_rating: "adult" },
        { id: 10, title: "Administrative Tools", type: "admin", age_rating: "admin_only" },
        { id: 11, title: "Analytics Dashboard", type: "analytics", age_rating: "admin_only" }
      ]
    }

    case @user.age_group
    when :child
      # Children get child-safe content only
      demo_content[:child]
    when :teen
      # Teens get teen content + child content
      demo_content[:child] + demo_content[:teen]
    when :adult, :senior
      # Adults get all content based on their role
      membership = @user.memberships.find_by(organization: @organization)
      if membership&.role == "admin"
        demo_content[:child] + demo_content[:teen] + demo_content[:adult]
      else
        demo_content[:child] + demo_content[:teen] + demo_content[:adult].reject { |c| c[:age_rating] == "admin_only" }
      end
    else
      []
    end
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
