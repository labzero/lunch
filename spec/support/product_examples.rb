RSpec.shared_examples 'a product page' do |action, method=:get|
  it_behaves_like 'a user required action', method, action
  before { send(method, action) }
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
