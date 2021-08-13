# name: Panel groups
# about: Synchronize groups with API
# version: 0.0.2
# authors: Piotr Szmielew

require 'open-uri'
require 'json'

module ::PanelGroups
  def self.connect
    uri = SiteSetting.panel_uri
  end

  def self.update_groups!
    return unless SiteSetting.panel_groups_enabled

    groups = JSON.parse(URI.open(self.connect() + "/api/v2/groups?token=" + SiteSetting.panel_token).read)

    groups.each_pair do |name, external_id|
      self.update_from_panel_entry name, external_id
    end

    query = "UPDATE groups g SET user_count = (SELECT COUNT(user_id) FROM group_users gu WHERE gu.group_id = g.id)"

    ActiveRecord::Base.connection_pool.with_connection { |con| con.exec_query(query) }
  end

  def self.update_from_panel_entry(name, group_external_id)
    users = JSON.parse(URI.open(self.connect() + "/api/v2/groups/#{group_external_id}?token=" + SiteSetting.panel_token).read)
    members = users.collect do |m|
      record = SingleSignOnRecord.find_by external_id: m
      next unless record

      User.find record.user_id
    end
    members.compact! # remove nils from users not in discourse

    # Find existing group or create a new one
    field = GroupCustomField.find_by(
      name: 'external_id',
      value: group_external_id
    )
    if field && field.group
      group = field.group
    else
      g_name = UserNameSuggester.suggest(name)
      puts "panel_group: Creating new group '#{g_name}' for external '#{name}'"

      group = Group.new name: g_name
      group.visibility_level = 1
      group.custom_fields['external_id'] = group_external_id
      group.save!
    end

    group.users = members
    group.save!
  end
end

after_initialize do
  module ::PanelGroups
    class UpdateJob < ::Jobs::Scheduled
      every 1.hour

      def execute(args)
        return unless SiteSetting.panel_groups_enabled
        PanelGroups.update_groups!
      end
    end
  end
end
