RSpec.shared_examples 'an admin controller' do
  it { should_not use_before_filter(:require_member) }
  it { should use_before_filter(:require_admin) }

  it 'uses the `admin` layout' do
    expect(described_class._layout).to eq('admin')
  end
end