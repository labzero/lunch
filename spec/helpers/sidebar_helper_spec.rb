require 'rails_helper'

describe SidebarHelper, type: :helper do
  describe 'the `content_with_sidebar` method' do
    let(:sidebar_1) { {name: SecureRandom.hex, locals: instance_double(Hash)} }
    let(:sidebar_1_haml) { SecureRandom.hex }
    let(:sidebar_2) { {name: SecureRandom.hex, locals: instance_double(Hash)} }
    let(:sidebar_2_haml) { SecureRandom.hex }
    let(:sidebar_haml) { SecureRandom.hex }
    let(:main_content) { SecureRandom.hex }
    let(:call_method) { helper.content_with_sidebar([sidebar_1, sidebar_2]) {main_content} }

    before do
      allow(helper).to receive(:render)
      allow(helper).to receive(:content_tag).and_return('')
    end
    it 'handles being passed a single sidebar hash as an argument' do
      expect{helper.content_with_sidebar(sidebar_1) {main_content}}.not_to raise_error
    end
    it 'renders each passed sidebar partial along with its locals' do
      expect(helper).to receive(:render).with(partial: "sidebars/#{sidebar_1[:name]}", locals: sidebar_1[:locals])
      expect(helper).to receive(:render).with(partial: "sidebars/#{sidebar_2[:name]}", locals: sidebar_2[:locals])
      call_method
    end
    it 'captures the passed content block inside of a content_tag div with a class of `column-9x3-left`' do
      expect(helper).to receive(:content_tag).with(:div, class: 'column-9x3-left', &Proc.new{main_content})
      call_method
    end
    it 'captures the rendered sidebars inside of a content_tag div with a class of `column-9x3-right`' do
      allow(helper).to receive(:render).and_return(sidebar_1_haml, sidebar_2_haml)
      expect(helper).to receive(:content_tag).with(:div, (sidebar_1_haml + sidebar_2_haml), class: 'column-9x3-right')
      call_method
    end
    it 'returns the combined `main_content` and `sidebar` divs' do
      allow(helper).to receive(:content_tag).and_return(main_content, sidebar_haml)
      expect(call_method).to eq(main_content + sidebar_haml)
    end
  end
end