module PanelGroups
  class ExMembersUnsubscribe
    def self.run
      return unless SiteSetting.panel_groups_enabled

      ex_group = Group.find_by(name: 'byly_czlonek')
      return unless ex_group

      ex_group.users.each do |user|
        disable_email_notification_for(user)
      end
    end
  end

  def self.disable_email_notification_for(user)
    user.user_option.update(
      mailing_list_mode: false,
      email_digests: false,
      allow_private_messages: false,
      like_notification_frequency: 3,
      notification_level_when_replying: 2,
      email_in_reply_to: false,
      email_level: 2,
      email_messages_level: 2
    )
    user.category_users.update_all(
      notification_level: CategoryUser.notification_levels[:muted]
    )
    user.tag_users.update_all(
      notification_level: TagUser.notification_levels[:muted]
    )
  end
end
