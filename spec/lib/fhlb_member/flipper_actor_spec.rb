require 'rails_helper'

RSpec.describe FhlbMember::FlipperActor do
  describe '`initialize` method' do
    it 'assigns the supplied flipper_id to the flipper_id attribute' do
      flipper_id = double('A Flipper ID')
      expect(described_class.new(flipper_id).flipper_id).to be(flipper_id)
    end
    it 'raises an error if passed nil' do
      expect{described_class.new(nil)}.to raise_error(ArgumentError)
    end
    it 'raises an error if passed false' do
      expect{described_class.new(false)}.to raise_error(ArgumentError)
    end
  end
  describe '`wrap` class method' do
    it 'returns the supplied actor if it responds to `flipper_id`' do
      actor = double('An Actor', flipper_id: SecureRandom.hex)
      expect(described_class.wrap(actor)).to be(actor)
    end
    describe 'if the actor does not respond to `flipper_id`' do
      let(:actor) { SecureRandom.hex }
      it 'returns a new FlipperActor' do
        expect(described_class.wrap(actor)).to be_kind_of(described_class)
      end
      it 'sets the `flipper_id` of the new instace to the actor' do
        expect(described_class.wrap(actor).flipper_id).to be(actor)
      end
    end
  end
end