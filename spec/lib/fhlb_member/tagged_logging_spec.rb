require 'rails_helper'

RSpec.describe FhlbMember::TaggedLogging do
  it 'includes `ActiveSupport::TaggedLogging`' do
    expect(described_class.included_modules).to include(ActiveSupport::TaggedLogging)
  end
  describe '`new` class method' do
    let(:logger) { ActiveSupport::Logger.new(STDOUT) }
    let(:call_method) { described_class.new(logger) }
    it 'sets the formatter on the logger if not set' do
      logger.formatter = nil
      expect(logger).to receive(:formatter=).with(kind_of(ActiveSupport::Logger::SimpleFormatter)).and_call_original # otherwise we EXTEND NIL
      call_method
    end
    it 'does not set the formtter on the logger if set' do
      expect(logger).to_not receive(:formatter=).with(kind_of(ActiveSupport::Logger::SimpleFormatter))
      call_method
    end
    it 'extends the formatter with `FhlbMember::TaggedLogging::Formatter`' do
      expect(logger.formatter).to receive(:extend).with(FhlbMember::TaggedLogging::Formatter)
      call_method
    end
    it 'extends the logger with `self`' do
      expect(logger).to receive(:extend).with(described_class)
      call_method
    end
  end

  describe described_class::Formatter do
    it 'includes `ActiveSupport::TaggedLogging::Formatter`' do
      expect(described_class.included_modules).to include(ActiveSupport::TaggedLogging::Formatter)
    end
    describe '`tags_text` instance method' do
      subject { Class.new { include FhlbMember::TaggedLogging::Formatter }.new }
      let(:call_method) { subject.tags_text }
      before do
        allow(subject).to receive(:current_tags).and_return([])
      end
      it 'fetches the current tags' do
        expect(subject).to receive(:current_tags).and_return([])
        call_method
      end
      it 'returns nil if there are no tags' do
        expect(call_method).to be_nil
      end
      it 'returns a string of the tags joined together' do
        tags = [] << SecureRandom.hex << SecureRandom.hex << SecureRandom.hex
        output_string = tags.collect { |tag| "[#{tag}] "}.join
        allow(subject).to receive(:current_tags).and_return(tags)
        expect(call_method).to eq(output_string)
      end
      it 'evaluates any Procs found in the current tags and puts their return value into the string returned' do
        tags = [] << SecureRandom.hex << SecureRandom.hex << SecureRandom.hex
        proc_tag_return = SecureRandom.hex
        output_string = (tags + [proc_tag_return]).collect { |tag| "[#{tag}] "}.join
        tags.append lambda { proc_tag_return }
        allow(subject).to receive(:current_tags).and_return(tags)
        expect(call_method).to eq(output_string)
      end
    end
  end
end