# frozen_string_literal: true

module Legion
  module Extensions
    module Acp
      module Transport
        class Stdio
          attr_reader :input, :output, :error

          def initialize(input: $stdin, output: $stdout, error: $stderr)
            @input  = input
            @output = output
            @error  = error
            @open   = false
          end

          def run(&handler)
            @open = true
            while @open
              msg = Helpers::Protocol.read(@input)
              break if msg.nil?

              if msg.key?(:error)
                send_response(msg)
                next
              end

              is_notification = !msg.key?(:id)

              result = handler.call(msg)

              next if is_notification

              resp = if result.nil?
                       Helpers::Protocol.response(id: msg[:id], result: {})
                     elsif result.is_a?(Hash) && result.key?(:error)
                       result.merge(jsonrpc: '2.0', id: msg[:id])
                     else
                       Helpers::Protocol.response(id: msg[:id], result: result)
                     end
              send_response(resp)
            end
          rescue Interrupt
            # Clean exit on SIGINT
          end

          def send_response(message)
            Helpers::Protocol.write(@output, message)
          end

          def send_notification(method, params = nil)
            notif = Helpers::Protocol.notification(method: method, params: params)
            Helpers::Protocol.write(@output, notif)
          end

          def log(message)
            @error.puts("[lex-acp] #{message}")
            @error.flush
          end

          def close
            @open = false
          end
        end
      end
    end
  end
end
