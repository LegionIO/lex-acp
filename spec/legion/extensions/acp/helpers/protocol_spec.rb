# frozen_string_literal: true

RSpec.describe Legion::Extensions::Acp::Helpers::Protocol do
  let(:protocol) { described_class }

  describe '.parse' do
    it 'parses a valid JSON-RPC request' do
      json = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"clientInfo":{"name":"test"}}}'
      msg = protocol.parse(json)
      expect(msg).to include(jsonrpc: '2.0', id: 1, method: 'initialize')
      expect(msg[:params][:clientInfo][:name]).to eq('test')
    end

    it 'parses a notification (no id)' do
      json = '{"jsonrpc":"2.0","method":"session/update","params":{}}'
      msg = protocol.parse(json)
      expect(msg[:method]).to eq('session/update')
      expect(msg).not_to have_key(:id)
    end

    it 'returns parse error for invalid JSON' do
      msg = protocol.parse('not json{')
      expect(msg[:error][:code]).to eq(-32_700)
    end

    it 'returns invalid request for missing jsonrpc field' do
      msg = protocol.parse('{"id":1,"method":"foo"}')
      expect(msg[:error][:code]).to eq(-32_600)
    end

    it 'returns invalid request for missing method on request' do
      msg = protocol.parse('{"jsonrpc":"2.0","id":1}')
      expect(msg[:error][:code]).to eq(-32_600)
    end
  end

  describe '.request' do
    it 'builds a JSON-RPC request hash' do
      req = protocol.request(id: 1, method: 'initialize', params: { foo: 'bar' })
      expect(req).to eq(jsonrpc: '2.0', id: 1, method: 'initialize', params: { foo: 'bar' })
    end

    it 'omits params when nil' do
      req = protocol.request(id: 2, method: 'ping')
      expect(req).not_to have_key(:params)
    end
  end

  describe '.response' do
    it 'builds a success response' do
      resp = protocol.response(id: 1, result: { name: 'LegionIO' })
      expect(resp).to eq(jsonrpc: '2.0', id: 1, result: { name: 'LegionIO' })
    end
  end

  describe '.error_response' do
    it 'builds an error response' do
      resp = protocol.error_response(id: 1, code: -32_601, message: 'Method not found')
      expect(resp[:error][:code]).to eq(-32_601)
      expect(resp[:error][:message]).to eq('Method not found')
    end

    it 'builds error response with nil id for parse errors' do
      resp = protocol.error_response(id: nil, code: -32_700, message: 'Parse error')
      expect(resp[:id]).to be_nil
    end
  end

  describe '.notification' do
    it 'builds a notification (no id)' do
      notif = protocol.notification(method: 'session/update', params: { type: 'chunk' })
      expect(notif).to eq(jsonrpc: '2.0', method: 'session/update', params: { type: 'chunk' })
      expect(notif).not_to have_key(:id)
    end
  end

  describe '.serialize' do
    it 'converts hash to JSON string' do
      json = protocol.serialize({ jsonrpc: '2.0', id: 1, result: {} })
      parsed = JSON.parse(json)
      expect(parsed['jsonrpc']).to eq('2.0')
    end
  end

  describe '.read' do
    it 'reads one line from IO and parses it' do
      io = StringIO.new("{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\"}\n")
      msg = protocol.read(io)
      expect(msg[:method]).to eq('initialize')
    end

    it 'returns nil on EOF' do
      io = StringIO.new('')
      expect(protocol.read(io)).to be_nil
    end

    it 'skips blank lines' do
      io = StringIO.new("\n\n{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"ping\"}\n")
      msg = protocol.read(io)
      expect(msg[:method]).to eq('ping')
    end
  end

  describe '.write' do
    it 'writes JSON followed by newline and flushes' do
      io = StringIO.new
      protocol.write(io, { jsonrpc: '2.0', id: 1, result: {} })
      expect(io.string).to end_with("\n")
      parsed = JSON.parse(io.string.strip)
      expect(parsed['id']).to eq(1)
    end
  end

  describe '.dispatch' do
    it 'routes to matching handler by method name' do
      called = false
      handlers = { 'initialize' => lambda { |_msg|
        called = true
        { name: 'test' }
      } }
      msg = { jsonrpc: '2.0', id: 1, method: 'initialize', params: {} }
      result = protocol.dispatch(msg, handlers)
      expect(called).to be true
      expect(result[:name]).to eq('test')
    end

    it 'returns method_not_found error for unknown method' do
      handlers = {}
      msg = { jsonrpc: '2.0', id: 1, method: 'unknown/method', params: {} }
      result = protocol.dispatch(msg, handlers)
      expect(result[:error][:code]).to eq(-32_601)
    end
  end
end
