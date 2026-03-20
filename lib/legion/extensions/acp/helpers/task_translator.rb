# frozen_string_literal: true

module Legion
  module Extensions
    module Acp
      module Helpers
        module TaskTranslator
          module_function

          def acp_to_legion(acp_task)
            input = acp_task[:input] || acp_task['input'] || {}
            {
              payload:      input.transform_keys(&:to_sym),
              source:       'acp',
              runner_class: acp_task[:runner_class],
              function:     acp_task[:function]
            }.compact
          end

          def legion_to_acp(legion_result)
            success = legion_result[:success]
            {
              task_id:      legion_result[:task_id],
              status:       success ? 'completed' : 'failed',
              output:       { data: legion_result[:result] || legion_result[:reason] },
              created_at:   legion_result[:created_at]&.to_s,
              completed_at: Time.now.utc.to_s
            }
          end
        end
      end
    end
  end
end
