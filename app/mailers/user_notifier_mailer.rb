class UserNotifierMailer < ApplicationMailer

  def notify_room_user(room)
    mail(:to => room.user.email, :subject => 'Thanks for signing up for our amazing app')
  end

  def notify_room_manager(room)
    mail(:to => room.manager.email, :subject => 'Thanks for signing up for our amazing app')
  end

end
