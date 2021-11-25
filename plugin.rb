# name: Panel groups
# about: Synchronize groups with API
# version: 0.0.3
# authors: Piotr Szmielew

require 'open-uri'
require 'json'

after_initialize do
  [
    '../lib/members_sync.rb',
    '../lib/ex_members_unsubscribe.rb'
  ].each { |path| load File.expand_path(path, __FILE__) }

  module ::PanelGroups
    class UpdateJob < ::Jobs::Scheduled
      every 6.hours

      def execute(_args)
        return unless SiteSetting.panel_groups_enabled

        PanelGroups::MembersSync.update_groups!
      end
    end
  end
end
