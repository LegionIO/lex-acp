# frozen_string_literal: true

require 'json'

module Legion
  module Extensions
    module Acp
      module Helpers
        module Protocol
          JSONRPC_VERSION = '2.0'

          PARSE_ERROR      = -32_700
          INVALID_REQUEST  = -32_600
          METHOD_NOT_FOUND = -32_601
          INVALID_PARAMS   = -32_602
          INTERNAL_ERROR   = -32_603

          module_function

          def parse(json_string)
            data = ::JSON.parse(json_string, symbolize_names: true)
            return error_response(id: nil, code: INVALID_REQUEST, message: 'Invalid Request') unless data.is_a?(Hash)
            return error_response(id: data[:id], code: INVALID_REQUEST, message: 'Invalid Request') unless data[:jsonrpc] == JSONRPC_VERSION

            return error_response(id: data[:id], code: INVALID_REQUEST, message: 'Invalid Request') if data.key?(:id) && !data.key?(:method)

            data
          rescue ::JSON::ParserError => _e
            error_response(id: nil, code: PARSE_ERROR, message: 'Parse error')
          end

          def request(id:, method:, params: nil)
            msg = { jsonrpc: JSONRPC_VERSION, id: id, method: method }
            msg[:params] = params if params
            msg
          end

          def response(id:, result:)
            { jsonrpc: JSONRPC_VERSION, id: id, result: result }
          end

          def error_response(id:, code:, message:, data: nil)
            err = { code: code, message: message }
            err[:data] = data if data
            { jsonrpc: JSONRPC_VERSION, id: id, error: err }
          end

          def notification(method:, params: nil)
            msg = { jsonrpc: JSONRPC_VERSION, method: method }
            msg[:params] = params if params
            msg
          end

          def serialize(hash)
            ::JSON.generate(hash)
          end

          def read(io)
            loop do
              line = io.gets
              return nil if line.nil?

              line = line.strip
              next if line.empty?

              return parse(line)
            end
          end

          def write(io, message)
            io.puts(serialize(message))
            io.flush
          end

          def dispatch(message, handlers)
            method_name = message[:method]
            handler = handlers[method_name]
            return error_response(id: message[:id], code: METHOD_NOT_FOUND, message: "Method not found: #{method_name}") unless handler

            handler.call(message)
          end
        end
      end
    end
  end
end
