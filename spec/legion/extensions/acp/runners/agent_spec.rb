# frozen_string_literal: true

RSpec.describe Legion::Extensions::Acp::Runners::Agent do
  let(:output) { StringIO.new }
  let(:transport) { instance_double(Legion::Extensions::Acp::Transport::Stdio, send_notification: nil, log: nil) }
  let(:agent) { described_class.new(transport: transport) }

  describe '#handle_initialize' do
    it 'returns agent info with capabilities' do
      msg = { id: 1, method: 'initialize', params: { clientInfo: { name: 'TestEditor', version: '1.0' } } }
      result = agent.handle_initialize(msg)
      expect(result[:name]).to eq('LegionIO')
      expect(result[:protocolVersion]).to eq(1)
      expect(result[:capabilities]).to be_a(Hash)
      expect(result[:authMethods]).to eq([])
    end

    it 'stores client info' do
      msg = { id: 1, method: 'initialize', params: { clientInfo: { name: 'Zed', version: '2.0' } } }
      agent.handle_initialize(msg)
      expect(agent.client_info[:name]).to eq('Zed')
    end

    it 'sends AvailableCommandsUpdate notification after init' do
      msg = { id: 1, method: 'initialize', params: { clientInfo: { name: 'Test' } } }
      agent.handle_initialize(msg)
      expect(transport).to have_received(:send_notification).with('session/update', hash_including(:commands))
    end
  end

  describe '#handle_session_new' do
    it 'creates a new session and returns session ID' do
      msg = { id: 2, method: 'session/new', params: {} }
      result = agent.handle_session_new(msg)
      expect(result[:sessionId]).to be_a(String)
      expect(result[:sessionId]).not_to be_empty
    end

    it 'creates unique session IDs' do
      result1 = agent.handle_session_new({ id: 2, method: 'session/new', params: {} })
      result2 = agent.handle_session_new({ id: 3, method: 'session/new', params: {} })
      expect(result1[:sessionId]).not_to eq(result2[:sessionId])
    end
  end

  describe '#handle_session_list' do
    it 'returns empty list when no sessions' do
      result = agent.handle_session_list({ id: 3, method: 'session/list', params: {} })
      expect(result[:sessions]).to eq([])
    end

    it 'returns created sessions' do
      agent.handle_session_new({ id: 2, method: 'session/new', params: {} })
      result = agent.handle_session_list({ id: 3, method: 'session/list', params: {} })
      expect(result[:sessions].size).to eq(1)
    end
  end

  describe '#handle_session_cancel' do
    before do
      resp = agent.handle_session_new({ id: 2, method: 'session/new', params: {} })
      @session_id = resp[:sessionId]
    end

    it 'marks session as cancelled' do
      msg = { id: 4, method: 'session/cancel', params: { sessionId: @session_id } }
      result = agent.handle_session_cancel(msg)
      expect(result[:success]).to be true
    end

    it 'returns error for unknown session' do
      msg = { id: 4, method: 'session/cancel', params: { sessionId: 'nonexistent' } }
      result = agent.handle_session_cancel(msg)
      expect(result[:error]).to include('not found')
    end
  end

  describe '#handle_session_set_mode' do
    before do
      resp = agent.handle_session_new({ id: 2, method: 'session/new', params: {} })
      @session_id = resp[:sessionId]
    end

    it 'updates session mode' do
      msg = { id: 5, method: 'session/set_mode', params: { sessionId: @session_id, mode: 'code' } }
      result = agent.handle_session_set_mode(msg)
      expect(result[:success]).to be true
      expect(result[:mode]).to eq('code')
    end
  end

  describe '#handle_session_set_config_option' do
    before do
      resp = agent.handle_session_new({ id: 2, method: 'session/new', params: {} })
      @session_id = resp[:sessionId]
    end

    it 'updates session config' do
      msg = { id: 6, method: 'session/set_config_option', params: { sessionId: @session_id, key: 'model', value: 'claude-sonnet-4-6' } }
      result = agent.handle_session_set_config_option(msg)
      expect(result[:success]).to be true
    end
  end

  describe '#dispatch' do
    it 'routes initialize to handle_initialize' do
      msg = { id: 1, method: 'initialize', params: { clientInfo: { name: 'Test' } } }
      result = agent.dispatch(msg)
      expect(result[:name]).to eq('LegionIO')
    end

    it 'routes session/new to handle_session_new' do
      msg = { id: 2, method: 'session/new', params: {} }
      result = agent.dispatch(msg)
      expect(result[:sessionId]).to be_a(String)
    end

    it 'returns method_not_found for unknown methods' do
      msg = { id: 99, method: 'unknown/method', params: {} }
      result = agent.dispatch(msg)
      expect(result[:error][:code]).to eq(-32_601)
    end
  end
end
