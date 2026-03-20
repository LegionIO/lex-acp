# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module Legion
  module Extensions
    module Acp
      module Helpers
        module AgentCard
          CARD_PATH = '/.well-known/agent.json'
          FETCH_TIMEOUT = 5

          module_function

          def build(name:, url:, capabilities: [], description: nil)
            {
              name:               name,
              description:        description || 'LegionIO digital worker',
              url:                url,
              version:            '2.0',
              protocol:           'acp/1.0',
              capabilities:       capabilities,
              authentication:     { schemes: ['bearer'] },
              defaultInputModes:  ['text/plain', 'application/json'],
              defaultOutputModes: ['text/plain', 'application/json']
            }
          end

          def parse(json)
            data = if json.is_a?(String)
                     ::JSON.parse(json, symbolize_names: true)
                   else
                     json.transform_keys(&:to_sym)
                   end
            return nil unless data[:name] && data[:url]

            data
          rescue ::JSON::ParserError, StandardError
            nil
          end

          def fetch(base_url, timeout: FETCH_TIMEOUT)
            uri = URI.join(base_url.chomp('/') + '/', CARD_PATH.delete_prefix('/'))
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = uri.scheme == 'https'
            http.open_timeout = timeout
            http.read_timeout = timeout

            response = http.get(uri.request_uri)
            return nil unless response.is_a?(Net::HTTPSuccess)

            parse(response.body)
          rescue StandardError
            nil
          end
        end
      end
    end
  end
end
