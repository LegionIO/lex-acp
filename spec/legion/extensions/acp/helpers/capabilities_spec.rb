# frozen_string_literal: true

RSpec.describe Legion::Extensions::Acp::Helpers::Capabilities do
  let(:caps) { described_class }

  describe '.agent_capabilities' do
    context 'when LLM is available' do
      before do
        stub_const('Legion::LLM', Module.new)
        allow(Legion::LLM).to receive(:started?).and_return(true)
      end

      it 'includes promptCapabilities' do
        result = caps.agent_capabilities
        expect(result[:promptCapabilities]).to include(supportedMediaTypes: ['text/plain'])
      end

      it 'includes loadSession capability' do
        result = caps.agent_capabilities
        expect(result[:loadSession]).to be true
      end

      it 'includes sessionCapabilities' do
        result = caps.agent_capabilities
        expect(result[:sessionCapabilities]).to include(supportedModes: %w[code chat])
      end
    end

    context 'when LLM is not available' do
      before do
        hide_const('Legion::LLM') if defined?(Legion::LLM)
      end

      it 'omits promptCapabilities' do
        result = caps.agent_capabilities
        expect(result).not_to have_key(:promptCapabilities)
      end

      it 'still includes loadSession' do
        result = caps.agent_capabilities
        expect(result[:loadSession]).to be true
      end
    end
  end

  describe '.agent_info' do
    it 'returns name and version' do
      info = caps.agent_info
      expect(info[:name]).to eq('LegionIO')
      expect(info[:version]).to be_a(String)
    end

    it 'includes protocolVersion' do
      info = caps.agent_info
      expect(info[:protocolVersion]).to eq(1)
    end

    it 'includes empty authMethods' do
      info = caps.agent_info
      expect(info[:authMethods]).to eq([])
    end
  end

  describe '.custom_commands' do
    it 'returns the four built-in commands' do
      cmds = caps.custom_commands
      names = cmds.map { |c| c[:name] }
      expect(names).to include('run_task', 'list_extensions', 'query_workers', 'list_schedules')
    end

    it 'each command has name and description' do
      cmds = caps.custom_commands
      cmds.each do |cmd|
        expect(cmd).to have_key(:name)
        expect(cmd).to have_key(:description)
      end
    end
  end
end
