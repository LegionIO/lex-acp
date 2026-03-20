# frozen_string_literal: true

RSpec.describe Legion::Extensions::Acp::Transport::Stdio do
  let(:input)  { StringIO.new }
  let(:output) { StringIO.new }
  let(:error)  { StringIO.new }
  let(:transport) { described_class.new(input: input, output: output, error: error) }

  describe '#initialize' do
    it 'accepts custom IO objects' do
      expect(transport).to be_a(described_class)
    end
  end

  describe '#send_response' do
    it 'writes JSON to output followed by newline' do
      transport.send_response({ jsonrpc: '2.0', id: 1, result: {} })
      output.rewind
      line = output.gets
      parsed = JSON.parse(line)
      expect(parsed['id']).to eq(1)
    end

    it 'flushes after each write' do
      allow(output).to receive(:flush).and_call_original
      transport.send_response({ jsonrpc: '2.0', id: 1, result: {} })
      expect(output).to have_received(:flush)
    end
  end

  describe '#send_notification' do
    it 'writes a notification without id' do
      transport.send_notification('session/update', { type: 'chunk' })
      output.rewind
      parsed = JSON.parse(output.gets)
      expect(parsed['method']).to eq('session/update')
      expect(parsed).not_to have_key('id')
    end
  end

  describe '#log' do
    it 'writes to stderr' do
      transport.log('debug message')
      error.rewind
      expect(error.gets).to include('debug message')
    end
  end

  describe '#run' do
    it 'reads messages and dispatches to handler' do
      request = { jsonrpc: '2.0', id: 1, method: 'initialize', params: {} }
      input = StringIO.new("#{JSON.generate(request)}\n")
      transport = described_class.new(input: input, output: output, error: error)

      called_with = nil
      transport.run do |msg|
        called_with = msg
        { name: 'LegionIO' }
      end

      expect(called_with[:method]).to eq('initialize')
      output.rewind
      resp = JSON.parse(output.gets)
      expect(resp['result']['name']).to eq('LegionIO')
    end

    it 'sends error response for parse errors' do
      input = StringIO.new("not valid json\n")
      transport = described_class.new(input: input, output: output, error: error)

      transport.run { |_msg| {} }

      output.rewind
      resp = JSON.parse(output.gets)
      expect(resp['error']['code']).to eq(-32_700)
    end

    it 'stops on EOF' do
      input = StringIO.new('')
      transport = described_class.new(input: input, output: output, error: error)
      expect { transport.run { |_| {} } }.not_to raise_error
    end

    it 'does not send response for notifications' do
      notif = { jsonrpc: '2.0', method: 'session/update', params: {} }
      input = StringIO.new("#{JSON.generate(notif)}\n")
      transport = described_class.new(input: input, output: output, error: error)

      transport.run { |_msg| { result: 'ignored' } }

      output.rewind
      expect(output.gets).to be_nil
    end

    it 'handles handler returning nil gracefully' do
      request = { jsonrpc: '2.0', id: 1, method: 'test', params: {} }
      input = StringIO.new("#{JSON.generate(request)}\n")
      transport = described_class.new(input: input, output: output, error: error)

      transport.run { |_msg| nil }

      output.rewind
      resp = JSON.parse(output.gets)
      expect(resp['result']).to eq({})
    end
  end

  describe '#close' do
    it 'stops the run loop' do
      req1 = JSON.generate({ jsonrpc: '2.0', id: 1, method: 'shutdown', params: {} })
      req2 = JSON.generate({ jsonrpc: '2.0', id: 2, method: 'after_shutdown', params: {} })
      input = StringIO.new("#{req1}\n#{req2}\n")
      transport = described_class.new(input: input, output: output, error: error)

      methods_seen = []
      transport.run do |msg|
        methods_seen << msg[:method]
        transport.close if msg[:method] == 'shutdown'
        {}
      end

      expect(methods_seen).to eq(['shutdown'])
    end
  end
end
