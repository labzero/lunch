require 'rails_helper'

describe ModelLogger do
  subject { mock_context(klass: ModelLogger) }
  let(:described_class) { subject.class }
  let(:log_prefix) { SecureRandom.hex }

  before { described_class.const_set('LOG_PREFIX', log_prefix) }

  describe 'protected instance methods' do
    describe '`log`' do
      let(:level) { double('A Log Level') }
      let(:block) { Proc.new {} }
      let(:call_method) { subject.send(:log, level, &block) }
      it 'calls `log` on the class with the supplied level and block' do
        expect(described_class).to receive(:log).with(level) do |*args, &proc|
          expect(proc).to be(block)
        end
        call_method
      end
      it 'uses `info` if no level has been provided' do
        expect(described_class).to receive(:log).with(:info)
        subject.send(:log)
      end
    end
  end

  describe 'class methods' do
    describe '`log`' do
      let(:level) { double('A Log Level') }
      let(:message)  { double('A Message', to_s: SecureRandom.hex) }
      let(:block) { Proc.new { message } }
      let(:call_method) { described_class.log(level, &block) }

      it 'calls the Rails logger with the supplied level' do
        expect(Rails.logger).to receive(:send).with(level)
        call_method
      end
      it 'uses level `info` if none is provided' do
        expect(Rails.logger).to receive(:info)
        described_class.log
      end
      it 'the Rails logger block calls the supplied block and prepends the `LOG_PREFIX` to its results' do
        allow(Rails.logger).to receive(:send).with(level) do |*args, &block|
          expect(block.call).to eq(described_class::LOG_PREFIX + message.to_s)
        end
        call_method
      end
    end
  end
end