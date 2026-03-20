# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require_relative '../helpers/agent_card'
require_relative '../helpers/task_translator'

module Legion
  module Extensions
    module Acp
      module Runners
        module Acp
          def invoke_agent(agent_url:, task:, timeout: 30, **)
            card = Helpers::AgentCard.fetch(agent_url)
            return { success: false, reason: :unreachable } unless card

            register_in_mesh(card, agent_url)
            response = submit_acp_task(card[:url], task, timeout)
            { success: true, task_id: response[:task_id], result: response[:output] }
          rescue StandardError => e
            { success: false, reason: :error, message: e.message }
          end

          def register_external(agent_url:, **)
            card = Helpers::AgentCard.fetch(agent_url)
            return { success: false, reason: :unreachable } unless card

            register_in_mesh(card, agent_url)
            { success: true, agent_id: card[:name] }
          rescue StandardError => e
            { success: false, reason: :error, message: e.message }
          end

          def list_agents(**)
            agents = mesh_registry.all_agents
            { success: true, agents: agents, count: agents.size }
          rescue StandardError => e
            { success: false, reason: :error, message: e.message }
          end

          def discover_agents(**)
            urls = acp_settings[:agents] || []
            registered = 0
            urls.each do |url|
              result = register_external(agent_url: url)
              registered += 1 if result[:success]
            end
            { success: true, scanned: urls.size, registered: registered }
          rescue StandardError => e
            { success: false, reason: :error, message: e.message }
          end

          private

          def submit_acp_task(agent_url, task, timeout)
            uri = URI.join(agent_url.chomp('/') + '/', 'tasks')
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = uri.scheme == 'https'
            http.open_timeout = timeout
            http.read_timeout = timeout

            request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
            request.body = ::JSON.dump(task)
            response = http.request(request)

            ::JSON.parse(response.body, symbolize_names: true)
          end

          def register_in_mesh(card, agent_url)
            return unless defined?(Legion::Extensions::Mesh)

            mesh = mesh_registry
            mesh.register_agent(
              card[:name],
              capabilities: (card[:capabilities] || []).map(&:to_sym),
              endpoint:     agent_url,
              source:       :acp
            )
          rescue StandardError
            nil
          end

          def mesh_registry
            @mesh_registry ||= if defined?(Legion::Extensions::Mesh::Helpers::Registry)
                                 Legion::Extensions::Mesh::Helpers::Registry.new
                               end
          end

          def acp_settings
            Legion::Settings[:acp] || {}
          rescue StandardError
            {}
          end
        end
      end
    end
  end
end
