# frozen_string_literal: true

module Legion
  module Extensions
    module Acp
      module Actor
        class Discovery < (defined?(Legion::Extensions::Actors::Every) ? Legion::Extensions::Actors::Every : Object) # rubocop:disable Legion/Extension/ActorInheritance
          class << self
            attr_accessor :time # rubocop:disable ThreadSafety/ClassAndModuleAttributes
          end
          self.time = 300

          def runner_class
            'Legion::Extensions::Acp::Runners::Acp'
          end

          def runner_function
            :discover_agents
          end

          def use_runner?
            true
          end

          def check_subtask?
            false
          end

          def generate_task?
            false
          end

          def args
            {}
          end
        end
      end
    end
  end
end
