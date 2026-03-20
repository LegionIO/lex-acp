# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/acp/helpers/agent_card'

RSpec.describe Legion::Extensions::Acp::Helpers::AgentCard do
  describe '.build' do
    it 'returns a hash with required ACP fields' do
      card = described_class.build(
        name: 'worker-01',
        url: 'https://legion:4567/api/acp',
        capabilities: %i[code_review planning]
      )
      expect(card[:name]).to eq('worker-01')
      expect(card[:url]).to eq('https://legion:4567/api/acp')
      expect(card[:capabilities]).to eq(%i[code_review planning])
      expect(card[:version]).to eq('2.0')
      expect(card[:protocol]).to eq('acp/1.0')
      expect(card[:authentication]).to eq({ schemes: ['bearer'] })
    end
  end

  describe '.parse' do
    it 'validates and returns parsed card' do
      json = { 'name' => 'ext-agent', 'url' => 'https://agent.example.com/api/acp' }
      card = described_class.parse(json)
      expect(card[:name]).to eq('ext-agent')
      expect(card[:url]).to eq('https://agent.example.com/api/acp')
    end

    it 'returns nil for invalid card (missing name)' do
      expect(described_class.parse({})).to be_nil
    end
  end

  describe '.fetch' do
    it 'returns nil when URL is unreachable' do
      expect(described_class.fetch('https://nonexistent.example.com')).to be_nil
    end
  end
end
