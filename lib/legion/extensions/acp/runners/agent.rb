# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Acp
      module Runners
        class Agent
          attr_reader :client_info, :sessions

          def initialize(transport:)
            @transport   = transport
            @client_info = {}
            @sessions    = {}
            @handlers    = build_handler_map
          end

          def dispatch(message)
            method_name = message[:method]
            handler = @handlers[method_name]
            unless handler
              return Helpers::Protocol.error_response(
                id:      message[:id],
                code:    Helpers::Protocol::METHOD_NOT_FOUND,
                message: "Method not found: #{method_name}"
              )
            end

            handler.call(message)
          end

          def handle_initialize(msg)
            @client_info         = msg.dig(:params, :clientInfo) || {}
            @client_capabilities = msg.dig(:params, :capabilities) || {}

            info = Helpers::Capabilities.agent_info

            @transport.send_notification('session/update', {
                                           commands: Helpers::Capabilities.custom_commands
                                         })

            info
          end

          def handle_session_new(_msg)
            session_id = SecureRandom.uuid
            @sessions[session_id] = {
              id:         session_id,
              created_at: Time.now.utc.iso8601,
              mode:       'code',
              config:     {},
              cancelled:  false
            }
            { sessionId: session_id }
          end

          def handle_session_list(_msg)
            session_list = @sessions.map do |id, session|
              { sessionId: id, createdAt: session[:created_at], mode: session[:mode] }
            end
            { sessions: session_list }
          end

          def handle_session_cancel(msg)
            session_id = msg.dig(:params, :sessionId)
            session = @sessions[session_id]
            return { error: "Session not found: #{session_id}" } unless session

            session[:cancelled] = true
            { success: true }
          end

          def handle_session_set_mode(msg)
            session_id = msg.dig(:params, :sessionId)
            session = @sessions[session_id]
            return { error: "Session not found: #{session_id}" } unless session

            mode = msg.dig(:params, :mode)
            session[:mode] = mode
            { success: true, mode: mode }
          end

          def handle_session_set_config_option(msg)
            session_id = msg.dig(:params, :sessionId)
            session = @sessions[session_id]
            return { error: "Session not found: #{session_id}" } unless session

            key   = msg.dig(:params, :key)
            value = msg.dig(:params, :value)
            session[:config][key.to_s] = value
            { success: true }
          end

          private

          def build_handler_map
            {
              'initialize'                => method(:handle_initialize),
              'session/new'               => method(:handle_session_new),
              'session/list'              => method(:handle_session_list),
              'session/cancel'            => method(:handle_session_cancel),
              'session/set_mode'          => method(:handle_session_set_mode),
              'session/set_config_option' => method(:handle_session_set_config_option)
            }
          end
        end
      end
    end
  end
end
