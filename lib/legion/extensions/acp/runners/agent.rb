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

          def handle_session_prompt(msg)
            session_id = msg.dig(:params, :sessionId)
            session = @sessions[session_id]
            return { error: "Session not found: #{session_id}" } unless session

            user_text = msg.dig(:params, :prompt, :userMessage, :content) || ''

            return handle_command(session, user_text) if user_text.start_with?('/')

            return { error: 'LLM not available — prompt handling requires legion-llm' } unless Helpers::Capabilities.llm_available?

            session[:cancelled] = false
            chat = Legion::LLM.chat(model: session[:config]['model'], provider: session[:config]['provider']&.to_sym)
            chat.with_instructions("You are LegionIO, an async job engine coding assistant. Mode: #{session[:mode]}.")

            full_content = +''
            response = chat.ask(user_text) do |chunk|
              next if session[:cancelled]

              text = chunk.respond_to?(:content) ? chunk.content : chunk.to_s
              next if text.nil? || text.empty?

              @transport.send_notification('session/update', { contentBlock: { type: 'text', text: text } })
              full_content << text
            end

            final_content = if response.respond_to?(:content) && !response.content.nil?
                              response.content
                            else
                              full_content
                            end

            stop_reason = session[:cancelled] ? 'cancelled' : 'end_turn'
            { stopReason: stop_reason, content: final_content }
          rescue StandardError => e
            { error: "Prompt failed: #{e.message}", stopReason: 'error' }
          end

          private

          def handle_command(_session, text)
            parts   = text.sub(%r{^/}, '').split(' ', 2)
            command = parts[0]
            args    = parts[1]

            result = case command
                     when 'run_task'        then execute_run_task(args)
                     when 'list_extensions' then execute_list_extensions
                     when 'query_workers'   then execute_query_workers
                     when 'list_schedules'  then execute_list_schedules
                     else
                       { content: "Unknown command: #{command}" }
                     end

            content = result.is_a?(Hash) ? ::JSON.generate(result) : result.to_s
            @transport.send_notification('session/update', { contentBlock: { type: 'text', text: content } })
            { stopReason: 'end_turn', content: content }
          end

          def execute_run_task(args)
            return { error: 'Ingress not available' } unless defined?(Legion::Ingress)
            return { error: 'Missing task arguments' } if args.nil? || args.empty?

            parts       = args.split
            runner_path = parts.shift
            path_parts  = runner_path.split('.')
            return { error: 'Invalid runner path — expected extension.runner.function' } unless path_parts.size >= 3

            function     = path_parts.pop
            runner_class = path_parts.map { |p| p.split('_').map(&:capitalize).join }.join('::')

            payload = {}
            parts.each do |pair|
              key, value = pair.split(':', 2)
              payload[key.to_sym] = value if key && value
            end

            Legion::Ingress.run(runner_class: runner_class, function: function, payload: payload, source: 'acp')
          end

          def execute_list_extensions
            if defined?(Legion::Extensions) && Legion::Extensions.respond_to?(:loaded_extensions)
              Legion::Extensions.loaded_extensions.map { |e| e.respond_to?(:name) ? e.name : e.to_s }
            else
              []
            end
          end

          def execute_query_workers
            if defined?(Legion::DigitalWorker::Registry)
              Legion::DigitalWorker::Registry.all.map { |w| { id: w.id, name: w.name, status: w.status } }
            else
              []
            end
          end

          def execute_list_schedules
            if defined?(Legion::Ingress)
              Legion::Ingress.run(runner_class: 'Runners::Scheduler', function: 'list', payload: {}, source: 'acp')
            else
              []
            end
          end

          def build_handler_map
            {
              'initialize'                => method(:handle_initialize),
              'session/new'               => method(:handle_session_new),
              'session/list'              => method(:handle_session_list),
              'session/cancel'            => method(:handle_session_cancel),
              'session/set_mode'          => method(:handle_session_set_mode),
              'session/set_config_option' => method(:handle_session_set_config_option),
              'session/prompt'            => method(:handle_session_prompt)
            }
          end
        end
      end
    end
  end
end
