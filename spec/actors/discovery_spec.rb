# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Acp::Actor::Discovery do
  it 'defines a 300 second interval' do
    expect(described_class.time).to eq(300)
  end

  it 'returns the correct runner function' do
    instance = described_class.allocate
    expect(instance.runner_function).to eq(:discover_agents)
  end
end
