# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/acp/helpers/task_translator'

RSpec.describe Legion::Extensions::Acp::Helpers::TaskTranslator do
  describe '.acp_to_legion' do
    it 'translates ACP task to Legion payload' do
      acp = { input: { text: 'Review PR', data: { repo: 'test' } } }
      result = described_class.acp_to_legion(acp)
      expect(result[:payload]).to include(:text, :data)
      expect(result[:source]).to eq('acp')
    end
  end

  describe '.legion_to_acp' do
    it 'wraps Legion result in ACP response format' do
      legion = { success: true, result: { summary: 'done' }, task_id: 123 }
      result = described_class.legion_to_acp(legion)
      expect(result[:task_id]).to eq(123)
      expect(result[:status]).to eq('completed')
      expect(result[:output]).to include(:data)
    end

    it 'maps failed results to failed status' do
      legion = { success: false, reason: :timeout }
      result = described_class.legion_to_acp(legion)
      expect(result[:status]).to eq('failed')
    end
  end
end
