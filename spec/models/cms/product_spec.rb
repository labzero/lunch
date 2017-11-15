require 'rails_helper'

RSpec.describe Cms::Product, :type => :model do
  let(:request) { double('request') }
  let(:member_id) { rand(1000..9999) }
  let(:cms_key) { instance_double(Symbol) }
  let(:cms) { instance_double(ContentManagementService, get_attribute_as_text: '') }
  let(:subject) { Cms::Product.new(member_id, request, cms_key, cms) }

  describe 'instance methods' do
    describe '`name`' do
      let(:name) { instance_double(String) }
      let(:call_method) { subject.name }

      context 'when the `name` attr has already been set' do
        before { subject.instance_variable_set(:@name, name) }

        it 'returns the attribute' do
          expect(call_method).to eq(name)
        end
        it 'does not call `get_attribute_as_text` on the cms' do
          expect(subject.cms).not_to receive(:get_attribute_as_text)
          call_method
        end
      end
      context 'when the `name` attr has not yet been set' do
        it 'calls `get_attribute_as_text` on the cms with the cms_key attribute and `product-page-name`' do
          expect(subject.cms).to receive(:get_attribute_as_text).with(subject.cms_key, 'product-page-name')
          call_method
        end
        it 'returns the result of calling `get_attribute_as_text`' do
          allow(subject.cms).to receive(:get_attribute_as_text).and_return(name)
          expect(call_method).to eq(name)
        end
        it 'returns the same object if called multiple times' do
          allow(subject.cms).to receive(:get_attribute_as_text).and_return(name)
          results = call_method
          expect(call_method).to be results
        end
      end
    end

    describe '`product_page_html`' do
      let(:product_page_html) { instance_double(String) }
      let(:call_method) { subject.product_page_html }

      context 'when the `product_page_html` attr has already been set' do
        before { subject.instance_variable_set(:@product_page_html, product_page_html) }

        it 'returns the attribute' do
          expect(call_method).to eq(product_page_html)
        end
        it 'does not call `get_attribute_as_html` on the cms' do
          expect(subject.cms).not_to receive(:get_attribute_as_html)
          call_method
        end
      end
      context 'when the `product_page_html` attr has not yet been set' do
        it 'calls `get_attribute_as_html` on the cms with the cms_key attribute and `product-page-body`' do
          expect(subject.cms).to receive(:get_attribute_as_html).with(subject.cms_key, 'product-page-body')
          call_method
        end
        it 'returns the result of calling `get_attribute_as_html`' do
          allow(subject.cms).to receive(:get_attribute_as_html).and_return(product_page_html)
          expect(call_method).to eq(product_page_html)
        end
        it 'returns the same object if called multiple times' do
          allow(subject.cms).to receive(:get_attribute_as_html).and_return(product_page_html)
          results = call_method
          expect(call_method).to be results
        end
      end
    end
  end
end