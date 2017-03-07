require 'rails_helper'

RSpec.describe RenderSecuritiesRequestsPDFJob, type: :job do
  it_behaves_like 'a job that initializes a controller', SecuritiesController

  it 'inherits from `RenderPDFJob`' do
    expect(described_class.superclass).to eq(RenderPDFJob)
  end

  describe '`render_footer_html`' do
    let(:controller) { double('controller', instance_variable_set: nil, params: {}, render_to_string: nil) }
    let(:call_method) { subject.render_footer_html }
    before { subject.instance_variable_set(:@controller, controller) }

    describe 'setting the `@footer_label` instance variable' do
      [
        ['pledge_release', I18n.t('securities.requests.view.pledge_release.footer')],
        ['safekept_release', I18n.t('securities.requests.view.safekept_release.footer')],
        ['pledge_intake', I18n.t('securities.requests.view.pledge_intake.footer')],
        ['safekept_intake', I18n.t('securities.requests.view.safekept_intake.footer')],
        ['pledge_transfer', I18n.t('securities.requests.view.pledge_transfer.footer')],
        ['safekept_transfer', I18n.t('securities.requests.view.safekept_transfer.footer')]
      ].each do |kind_pairing|
        it "sets `@footer_label` to `#{kind_pairing.last}` when the `kind` param is `#{kind_pairing.first}`" do
          controller.params[:kind] = kind_pairing.first
          expect(controller).to receive(:instance_variable_set).with(:@footer_label, kind_pairing.last)
          call_method
        end
      end
    end
    it 'calls `render_to_string` on the controller (via the `super` keyword) after setting the instance variable' do
      expect(controller).to receive(:instance_variable_set).ordered
      expect(controller).to receive(:render_to_string).ordered
      call_method
    end
  end

end
