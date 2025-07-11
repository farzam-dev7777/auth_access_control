class UserInviteMailer < ApplicationMailer
  def invite(user, organization, inviter, reset_token = nil)
    @user = user
    @organization = organization
    @inviter = inviter
    if reset_token
      @invite_url = edit_user_password_url(reset_password_token: reset_token)
    else
      @invite_url = new_user_session_url
    end
    mail(
      to: @user.email,
      subject: "You're invited to join #{organization.name}"
    )
  end
end
