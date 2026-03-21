# frozen_string_literal: true

require 'legion/extensions/acp/version'
require 'legion/extensions/acp/helpers/agent_card'
require 'legion/extensions/acp/helpers/task_translator'
require 'legion/extensions/acp/helpers/protocol'
require 'legion/extensions/acp/helpers/capabilities'
require 'legion/extensions/acp/transport/stdio'
require 'legion/extensions/acp/runners/acp'
require 'legion/extensions/acp/runners/agent'
require 'legion/extensions/acp/actors/discovery'

module Legion
  module Extensions
    module Acp
      extend Legion::Extensions::Core if defined?(Legion::Extensions::Core)

      def self.data_required?
        false
      end
    end
  end
end
