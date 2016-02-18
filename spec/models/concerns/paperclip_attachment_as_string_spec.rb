require 'rails_helper'

describe PaperclipAttachmentAsString do
  let(:example_class) {class SomeModel; def result; end; end; SomeModel }
  let(:example_instance) { example_class.new }
  before do
    allow(Paperclip::AttachmentRegistry).to receive(:names_for).with(example_class).and_return([:result, :data])
    example_class.class_eval do
      include PaperclipAttachmentAsString
    end
  end
  it 'creates a method for each attachment on the class' do
    expect(example_instance).to respond_to(:result_as_string)
    expect(example_instance).to respond_to(:data_as_string)
  end
  describe 'generated method' do
    let(:call_method) { example_instance.result_as_string }
    let(:data) { double('Some Data') }
    let(:tempfile) { double('A Tempfile', path: double('A Path'), read: data, unlink: nil) }
    let(:result) { double('Paperclip::Attachment', copy_to_local_file: nil) }
    before do
      allow(example_instance).to receive(:result).and_return(result)
      allow(Tempfile).to receive(:open).and_yield(tempfile)
    end
    it 'should open a Tempfile' do
      expect(Tempfile).to receive(:open).with('somemodel_result', Rails.root.join('tmp'))
      call_method
    end
    it 'should delete the Tempfile after reading it' do
      expect(tempfile).to receive(:read).ordered
      expect(tempfile).to receive(:unlink).ordered
      call_method
    end
    it 'should delete the Tempfile if an exception occurs' do
      expect(tempfile).to receive(:unlink)
      allow(tempfile).to receive(:read).and_raise('some error')
      expect{call_method}.to raise_error
    end
    it 'should copy the stored file to the Tempfile' do
      expect(result).to receive(:copy_to_local_file).with(:original, tempfile.path)
      call_method
    end
    it 'should return the contents of the Tempfile' do
      expect(call_method).to be(data)
    end
  end
end