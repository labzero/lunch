require 'rails_helper'

RSpec.describe FhlbMember::WardenProxy do
  let(:user) { double(User) }
  subject { described_class.new(user) }

  describe 'construction' do
    it 'raises an error if not passed an `authenticated_as` object' do
      expect{ described_class.new }.to raise_error(ArgumentError)
    end
  end
  describe 'authenticate' do
    it 'returns the `authenticated_as` object' do
      expect(subject.authenticate).to be(user)
    end
  end
  describe 'authenticate!' do
    it 'returns the result from `authenticate`' do
      result = double('A Result')
      allow(subject).to receive(:authenticate).and_return(result)
      expect(subject.authenticate!).to be(result)
    end
  end
  describe 'authenticate?' do
    let(:call_method) { subject.authenticate? }
    it 'returns the `true` if `authenticate` returns a truthy value' do
      allow(subject).to receive(:authenticate).and_return(double(Object))
      expect(call_method).to be(true)
    end
    it 'returns the `false` if `authenticate` returns a falsey value' do
      allow(subject).to receive(:authenticate)
      expect(call_method).to be(false)
    end
    it 'calls the supplied block if the result is `true`' do
      allow(subject).to receive(:authenticate).and_return(double(Object))
      expect{ |block| subject.authenticate? &block }.to yield_control
    end
    it 'does not call the supplied block if the result is `false`' do
      allow(subject).to receive(:authenticate)
      expect{ |block| subject.authenticate? &block }.to_not yield_control
    end
  end
  describe 'authenticated?' do
    let(:call_method) { subject.authenticated? }
    it 'returns the result of calling `authenticate`' do
      result = double('A Result')
      allow(subject).to receive(:authenticate?).and_return(result)
      expect(call_method).to be(result)
    end
    it 'calls the supplied block if the result is `true`' do
      allow(subject).to receive(:authenticate).and_return(double(Object))
      expect{ |block| subject.authenticated? &block }.to yield_control
    end
    it 'does not call the supplied block if the result is `false`' do
      allow(subject).to receive(:authenticate)
      expect{ |block| subject.authenticated? &block }.to_not yield_control
    end
  end
  describe 'unauthenticated?' do
    let(:call_method) { subject.unauthenticated? }
    it 'returns true if `authenticate?` returns false' do
      allow(subject).to receive(:authenticate?).and_return(false)
      expect(call_method).to be(true)
    end
    it 'returns false if `authenticate?` returns true' do
      allow(subject).to receive(:authenticate?).and_return(true)
      expect(call_method).to be(false)
    end
    it 'calls the supplied block if the result is `true`' do
      allow(subject).to receive(:authenticate).and_return(double(Object))
      expect{ |block| subject.unauthenticated? &block }.to yield_control
    end
    it 'does not call the supplied block if the result is `false`' do
      allow(subject).to receive(:authenticate)
      expect{ |block| subject.unauthenticated? &block }.to_not yield_control
    end
  end
end