require 'rails_helper'

RSpec.describe RenderReportPDFJob, type: :job do
  it_behaves_like 'a job that initializes a controller', ReportsController

  it 'inherits from `RenderPDFJob`' do
    expect(described_class.superclass).to eq(RenderPDFJob)
  end

  describe '`pdf_orientation`' do
    let(:controller) { double('controller', action_name: nil) }
    let(:call_method) { subject.pdf_orientation }
    before { subject.instance_variable_set(:@controller, controller) }
    ['advances_detail', :advances_detail].each do |action_name|
      it "returns :landscape if the controller\'s action_name is `#{action_name}`" do
        allow(controller).to receive(:action_name).and_return(action_name)
        expect(call_method).to eq(:landscape)
      end
    end
    it 'returns :portrait if the action_name is not `advances_detail`' do
      expect(call_method).to eq(:portrait)
    end
  end
end
