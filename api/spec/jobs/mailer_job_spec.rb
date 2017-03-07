require 'spec_helper'

if !defined?(ActionMailer)
  module ActionMailer
    class Base
    end
  end
end

describe MailerJob do
  describe '`perform` method' do
    let(:klass) { instance_double(Class, 'A Class') }
    let(:klass_name) {instance_double(String, 'A Class Name', constantize: klass) }
    let(:method_name) { instance_double(String, 'Method Name', to_sym: instance_double(Symbol, 'Method Name')) }
    let(:mailer_instance) { double('Mail::Message', deliver_now: true) }
    let(:args) { [double('An Arg'), double('An Arg')] }
    let(:call_method) { subject.perform(klass_name, method_name, *args) }

    before do
      allow(klass).to receive(:<).with(ActionMailer::Base).and_return(true)
      allow(klass).to receive(:public_send).with(method_name.to_sym, any_args).and_return(mailer_instance)
    end

    it 'constantizes the `class_name`' do
      expect(klass_name).to receive(:constantize)
      call_method
    end
    it 'raises an error if the class requested is not a mailer' do
      allow(klass).to receive(:<).with(ActionMailer::Base).and_return(false)
      expect{ call_method }.to raise_error(/not an ActionMailer::Base/)
    end
    it 'calls the `method_name` method on the requested class' do
      expect(klass).to receive(:public_send).with(method_name.to_sym, any_args).and_return(mailer_instance)
      call_method
    end
    it 'includes the supplied arguments when calling the method' do
      expect(klass).to receive(:public_send).with(anything, *args).and_return(mailer_instance)
      call_method
    end
    it 'calls `deliver_now` on the returned mailer instance' do
      expect(mailer_instance).to receive(:deliver_now)
      call_method
    end
  end
end