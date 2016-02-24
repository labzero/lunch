RSpec.shared_examples 'an ActiveRecord scope' do |method|
  it "responds to `#{method}` at the class level" do
    expect(described_class).to respond_to(method)
  end
  it "responds to `#{method} at the AREL level" do
    expect(described_class.all).to respond_to(method)
  end
end