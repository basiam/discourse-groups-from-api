# name: Panel groups
# about: Synchronize groups with API
# version: 0.0.3
# authors: Piotr Szmielew

require 'open-uri'
require 'json'

after_initialize do
  [
   '../lib/members_sync.rb'
  ].each { |path| load File.expand_path(path, __FILE__) }

  module ::PanelGroups
    class UpdateJob < ::Jobs::Scheduled
      every 1.day

      def execute(args)
        return unless SiteSetting.panel_groups_enabled
        PanelGroups::MemberSync.update_groups!
      end
    end
  end
end
