require 'rails_helper'
require 'securid_service' # because our name is weird

describe SecurIDService do
  let(:prefixed_username) { double('A Prefixed Username') }
  let(:username) { double('A Username') }
  let(:rsa_session) { double('RSA::SecurID::Session', authenticate: nil, change_pin: nil, cancel_pin: nil, resynchronize: nil, status: nil, resynchronize?: nil, change_pin?: nil, authenticated?: nil, denied?: nil) }
  let(:token) { Random.rand(999999).to_s.rjust(6, '0') }
  let(:pin) { Random.rand(9999).to_s.rjust(4, '0') }
  let(:session_status) { double('A Status') }
  subject { SecurIDService.new(username) }
  before do
    allow(SecurIDService::USERNAME_PREFIX).to receive(:+).with(username).and_return(prefixed_username)
    allow(RSA::SecurID::Session).to receive(:new).and_return(rsa_session)
  end

  describe 'private methods' do
    describe '`validate_token` method' do
      it 'should raise an error if the token is not 6 digits' do
        ['', '12345', '123a', 'asdads', "123456\n", "123\n123", '12', 'ab'].each do |token|
          expect{subject.send(:validate_token, token)}.to raise_error(SecurIDService::InvalidToken)
        end
      end
      it 'should not raise an error if the token is 6 digits' do
        expect{subject.send(:validate_token, '123456')}.to_not raise_error
      end
    end
    describe '`validate_pin` method' do
      it 'should raise an error if the token is not 4 digits' do
        ['', '12345', '123a', 'asdads', "123456\n", "123\n123", '12', 'ab'].each do |token|
          expect{subject.send(:validate_pin, token)}.to raise_error(SecurIDService::InvalidPin)
        end
      end
      it 'should not raise an error if the token is 4 digits' do
        expect{subject.send(:validate_pin, '1234')}.to_not raise_error
      end
    end
  end

  describe 'constructor' do
    it 'should prefix the username with `prod-`' do
      expect(subject.instance_variable_get(:@username)).to eq(prefixed_username)
    end
  end

  describe 'public methods' do
    before do
      allow(subject).to receive(:validate_token)
      allow(subject).to receive(:validate_pin)
    end

    describe '`authenticate` method' do
      let(:make_call) { subject.authenticate(pin, token) }
      it 'should validate the token' do
        expect(subject).to receive(:validate_token).with(token)
        make_call
      end
      it 'should validate the pin' do
        expect(subject).to receive(:validate_pin).with(pin)
        make_call
      end
      it 'should call authenticate on the session and return the result' do
        allow(rsa_session).to receive(:authenticate).and_return(session_status)
        expect(make_call).to be(session_status)
      end
      it 'should call authenticate on the session and pass the prefixed username and concatenated pin and token' do
        expect(rsa_session).to receive(:authenticate).with(prefixed_username, pin + token)
        make_call
      end
    end

    describe '`authenticate_without_pin` method' do
      let(:make_call) { subject.authenticate_without_pin(token) }
      it 'should validates the token' do
        expect(subject).to receive(:validate_token).with(token)
        make_call
      end
      it 'does not validate the pin' do
        expect(subject).to_not receive(:validate_pin)
        make_call
      end
      it 'calls authenticate on the session and return the result' do
        allow(rsa_session).to receive(:authenticate).and_return(session_status)
        expect(make_call).to be(session_status)
      end
      it 'calls authenticate on the session and pass the prefixed username and token' do
        expect(rsa_session).to receive(:authenticate).with(prefixed_username, token)
        make_call
      end
    end

    describe '`change_pin` method' do
      let(:make_call) { subject.change_pin(pin) }
      it 'should validate the pin' do
        expect(subject).to receive(:validate_pin).with(pin)
        make_call
      end
      it 'should call change_pin on the session and return the result' do
        expect(rsa_session).to receive(:change_pin).with(pin).and_return(session_status)
        expect(make_call).to be(session_status)
      end
    end

    describe '`cancel_pin` method' do
      it 'should call cancel_pin on the session and return the result' do
        expect(rsa_session).to receive(:cancel_pin).and_return(session_status)
        expect(subject.cancel_pin).to be(session_status)
      end
    end

    describe '`resynchronize` method' do
      let(:make_call) { subject.resynchronize(pin, token) }
      it 'should validate the token' do
        expect(subject).to receive(:validate_token).with(token)
        make_call
      end
      it 'should validate the pin' do
        expect(subject).to receive(:validate_pin).with(pin)
        make_call
      end
      it 'should call resynchronize on the session and return the result' do
        expect(rsa_session).to receive(:resynchronize).and_return(session_status)
        expect(make_call).to be(session_status)
      end
      it 'should call authenticate on the session and pass the concatenated pin and token' do
        expect(rsa_session).to receive(:resynchronize).with(pin + token)
        make_call
      end
    end
    [:status, :resynchronize?, :change_pin?, :authenticated?, :denied?].each do |method|
      describe "`#{method}` method" do
        let(:make_call) { subject.send(method) }
        it 'should call `#{method}` on the session' do
          expect(rsa_session).to receive(method)
          make_call
        end
        it 'should return the result' do
          allow(rsa_session).to receive(method).and_return(session_status)
          expect(make_call).to be(session_status)
        end
      end
    end
  end
end