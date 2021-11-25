module PanelGroups
  class ExMembersUnsubscribe

    def self.run
      return unless SiteSetting.panel_groups_enabled

      ex_group = Group.find_by(name: 'byly_czlonek')

      ex_group.users.each do |user|
        user.user_option.update(
           mailing_list_mode: false,
           email_digests: false,
           allow_private_messages: false,
           email_always: false,
           email_in_reply_to: false,
           email_level: 2,
           email_messages_level: 2,
         )
        user.category_users.update_all(
          notification_level: CategoryUser.notification_levels[:muted]
        )
        user.tag_users.update_all(
          notification_level: TagUser.notification_levels[:muted]
        )
      end
    end
  end
end
