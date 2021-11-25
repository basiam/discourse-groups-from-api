module PanelGroups
  class MembersSync
    def self.connect
      SiteSetting.panel_uri
    end

    def self.update_groups!
      return unless SiteSetting.panel_groups_enabled

      groups = JSON.parse(
        URI.open("#{connect}/api/v2/groups?token=#{SiteSetting.panel_token}").read
      )

      groups.each_pair do |name, external_id|
        update_from_panel_entry(name, external_id)
      end

      query = "UPDATE groups g SET user_count = (SELECT COUNT(user_id) FROM group_users gu WHERE gu.group_id = g.id)"

      ActiveRecord::Base.connection_pool.with_connection { |con| con.exec_query(query) }
    end

    def self.update_from_panel_entry(name, group_external_id)
      users = JSON.parse(
        URI.open(connect + "/api/v2/groups/#{group_external_id}?token=" + SiteSetting.panel_token).read
      )
      members = users.collect do |m|
        record = SingleSignOnRecord.find_by(external_id: m)
        next unless record

        User.find(record.user_id)
      end
      members.compact! # remove nils from users not in discourse

      # Find existing group or create a new one
      field = GroupCustomField.find_by(
        name: 'external_id',
        value: group_external_id
      )
      if field&.group
        group = field.group
      else
        g_name = UserNameSuggester.suggest(name)
        puts "panel_group: Creating new group '#{g_name}' for external '#{name}'"

        group = Group.new(name: g_name)
        group.visibility_level = 1
        group.custom_fields['external_id'] = group_external_id
        group.save!
      end

      group.users = members
      group.save!
    end
  end
end
