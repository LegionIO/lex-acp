# frozen_string_literal: true

module Legion
  module Extensions
    module Acp
      module Helpers
        module Capabilities
          PROTOCOL_VERSION = 1

          module_function

          def agent_info
            version = defined?(Legion::VERSION) ? Legion::VERSION : Acp::VERSION
            {
              name:            'LegionIO',
              version:         version,
              protocolVersion: PROTOCOL_VERSION,
              capabilities:    agent_capabilities,
              authMethods:     []
            }
          end

          def agent_capabilities
            caps = { loadSession: true }

            if llm_available?
              caps[:promptCapabilities] = {
                supportedMediaTypes:  ['text/plain'],
                supportedStopReasons: %w[end_turn cancelled error]
              }
              caps[:sessionCapabilities] = {
                supportedModes: %w[code chat]
              }
            end

            caps
          end

          def custom_commands
            [
              { name: 'run_task',        description: 'Invoke a Legion runner function (e.g. extension.runner.function key:val)' },
              { name: 'list_extensions', description: 'List loaded Legion extensions' },
              { name: 'query_workers',   description: 'Show digital worker status' },
              { name: 'list_schedules',  description: 'List scheduled jobs' }
            ]
          end

          def llm_available?
            defined?(Legion::LLM) && Legion::LLM.respond_to?(:started?) && Legion::LLM.started?
          end
        end
      end
    end
  end
end
