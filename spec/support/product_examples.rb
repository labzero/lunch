RSpec.shared_examples 'a ProductsController action that pulls content from the CMS' do |action, method=:get|
  let(:call_action) { send(method, action) }

  context 'when the `content-management-service` is enabled' do
    before { allow(controller).to receive(:feature_enabled?).with('content-management-system').and_return(true) }
    it "calls `set_body_html` with #{described_class::PRODUCTS_CMS_KEY_MAPPING[action]}" do
      expect(controller).to receive(:set_body_html).with(described_class::PRODUCTS_CMS_KEY_MAPPING[action])
      call_action
    end
  end
  context 'when the `content-management-service` is not enabled' do
    before { allow(controller).to receive(:feature_enabled?).with('content-management-system').and_return(false) }
    it "does not call `set_body_html`" do
      expect(controller).not_to receive(:set_body_html)
      call_action
    end
  end
end

RSpec.shared_examples 'a product page' do |action, method=:get|
  it_behaves_like 'a user required action', method, action
  it_behaves_like 'a controller action with an active nav setting', action, :products
  it_behaves_like 'a ProductsController action that pulls content from the CMS', action, method
  it 'sets the active nav to :products' do
    expect(controller).to receive(:set_active_nav).with(:products)
    send(method, action)
  end

  before do
    allow(controller).to receive(:set_body_html)
    send(method, action)
  end
  it 'should render the view' do
    expect(response.body).to render_template(action)
  end
  it 'sets the @last_modified instance variable' do
    expect(assigns[:last_modified]).to be_kind_of(Date)
  end
  it 'sets the @html_class instance variable' do
    expect(assigns[:html_class]).to eq('white-background')
  end
end
