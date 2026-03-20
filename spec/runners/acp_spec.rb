# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/acp/runners/acp'

RSpec.describe Legion::Extensions::Acp::Runners::Acp do
  subject { Object.new.extend(described_class) }

  describe '#invoke_agent' do
    it 'returns failure when agent is unreachable' do
      allow(Legion::Extensions::Acp::Helpers::AgentCard).to receive(:fetch).and_return(nil)
      result = subject.invoke_agent(agent_url: 'https://fake.example.com', task: { input: {} })
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:unreachable)
    end

    it 'returns success when agent responds' do
      card = { name: 'test-agent', url: 'https://fake.example.com/api/acp', capabilities: [] }
      allow(Legion::Extensions::Acp::Helpers::AgentCard).to receive(:fetch).and_return(card)
      allow(subject).to receive(:submit_acp_task).and_return({ task_id: 'abc', output: { text: 'done' } })
      allow(subject).to receive(:register_in_mesh)

      result = subject.invoke_agent(agent_url: 'https://fake.example.com', task: { input: {} })
      expect(result[:success]).to be true
      expect(result[:task_id]).to eq('abc')
    end
  end

  describe '#register_external' do
    it 'fetches card and registers in mesh' do
      card = { name: 'ext-agent', url: 'https://ext.example.com/api/acp', capabilities: [:planning] }
      allow(Legion::Extensions::Acp::Helpers::AgentCard).to receive(:fetch).and_return(card)
      allow(subject).to receive(:register_in_mesh)

      result = subject.register_external(agent_url: 'https://ext.example.com')
      expect(result[:success]).to be true
      expect(result[:agent_id]).to eq('ext-agent')
    end
  end

  describe '#list_agents' do
    it 'returns agent list' do
      allow(subject).to receive(:mesh_registry).and_return(
        double(all_agents: [{ agent_id: 'a1' }])
      )
      result = subject.list_agents
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
    end
  end
end
