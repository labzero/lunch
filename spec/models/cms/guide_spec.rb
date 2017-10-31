require 'rails_helper'

RSpec.describe Cms::Guide, :type => :model do
  let(:request) { double('request') }
  let(:member_id) { rand(1000..9999) }
  let(:cms_key) { instance_double(Symbol) }
  let(:cms) { instance_double(ContentManagementService, get_slices_by_type: []) }
  let(:subject) { Cms::Guide.new(member_id, request, cms_key, cms) }

  describe 'instance methods' do
    describe '`revisions`' do
      let(:call_method) { subject.revisions }

      context 'when the `revisions` attribute has already been set' do
        let(:revisions) { instance_double(Array) }
        before { subject.instance_variable_set(:@revisions, revisions) }

        it 'returns the `revisions` attribute' do
          expect(call_method).to eq(revisions)
        end
        it 'does not call `get_slices_by_type` on the `cms` attribute' do
          expect(subject.cms).not_to receive(:get_slices_by_type)
          call_method
        end
      end
      context 'when the `revisions` attribute has not yet been set' do
        before { subject.instance_variable_set(:@revisions, nil) }

        it 'calls `get_slices_by_type` on the `cms` attribute with the `cms_key` attribute and the `revision` keyword' do
          expect(subject.cms).to receive(:get_slices_by_type).with(subject.cms_key, 'revision')
          call_method
        end
        context 'when no slices are returned' do
          it 'returns an empty array' do
            expect(call_method).to eq([])
          end
        end
        context 'when slices are returned' do
          let(:revision) { instance_double(Cms::Guide::Revision, last_updated: nil) }
          it 'creates an instance of `Cms::Guide::Revision` for each slice' do
            slices = []
            n = rand(2..5)
            n.times do |i|
              slices << double('slice')
            end
            allow(subject.cms).to receive(:get_slices_by_type).and_return(slices)
            expect(Cms::Guide::Revision).to receive(:new).exactly(n).and_return(revision)
            call_method
          end
          it 'sorts the revisions by descending date' do
            revision_1 = instance_double(Cms::Guide::Revision, last_updated: Date.new(2017, 3, 4))
            revision_2 = instance_double(Cms::Guide::Revision, last_updated: Date.new(2018, 12, 14))
            revision_3 = instance_double(Cms::Guide::Revision, last_updated: Date.new(2017, 1, 30))
            allow(subject.cms).to receive(:get_slices_by_type).and_return([double('slice'), double('slice'), double('slice')])
            allow(Cms::Guide::Revision).to receive(:new).and_return(revision_1, revision_2, revision_3)
            expect(call_method).to eq([revision_2, revision_1, revision_3])
          end
        end
      end
    end

    describe '`last_revised_date`' do
      let(:call_method) { subject.last_revised_date }
      let(:last_revised_date) { instance_double(Date) }

      context 'when `revisions` are present' do
        let(:today) { Time.zone.today }
        let(:most_recent_date) { today + rand(1..30).days }
        let(:least_recent_date) { today - rand(1..30).days }
        let(:revision1) { instance_double(Cms::Guide::Revision, last_updated: today) }
        let(:revision2) { instance_double(Cms::Guide::Revision, last_updated: most_recent_date) }
        let(:revision3) { instance_double(Cms::Guide::Revision, last_updated: least_recent_date) }
        let(:revisions) { [revision1, revision2, revision3] }
        before { subject.instance_variable_set(:@revisions, revisions) }

        it 'returns the `last_updated` date from the most-recent revision' do
          expect(call_method).to eq(most_recent_date)
        end
      end
      context 'when no revisions are present' do
        before { subject.instance_variable_set(:@revisions, []) }

        it 'returns nil' do
          expect(call_method).to be nil
        end
      end
    end
  end
end

RSpec.describe Cms::Guide::Revision, :type => :model do
  let(:squished_html) { unescaped_html.gsub("<br><br /><br/>\n\t\n", '') }
  let(:unescaped_html) { SecureRandom.hex + "<br><br /><br/>\n\t\n" }
  let(:slice_html) { double('some html') }
  let(:revision_date_node) { double('node', value: Time.zone.today - rand(1..360).days) }
  let(:slice) { instance_double(Prismic::Fragments::CompositeSlice, non_repeat: {'revision_date' => revision_date_node}, as_html: slice_html) }
  let(:revision) { Cms::Guide::Revision.new(slice) }
  before { allow(CGI).to receive(:unescape_html).and_return(unescaped_html) }

  describe 'initialization' do
    describe 'setting the `last_updated` attribute' do
      it 'fetches the `non_repeat` part of the slice' do
        expect(slice).to receive(:non_repeat).and_return({'revision_date' => revision_date_node})
        revision
      end
      it 'returns the `value` of the `revision_date` node in the `repeat` section' do
        expect(revision.last_updated).to eq(revision_date_node.value)
      end
      it 'ensures that a date is returned for the `last_updated` attribute' do
        date_string = (Time.zone.today - rand(1..360).days).iso8601
        allow(revision_date_node).to receive(:value).and_return(date_string)
        expect(revision.last_updated).to eq(date_string.to_date)
      end
    end
    describe 'setting the `revision_list` attribute' do
      it 'turns the slice into html' do
        expect(slice).to receive(:as_html)
        revision
      end
      it 'unescapes the html to turn escaped html characters back into valid html' do
        expect(CGI).to receive(:unescape_html).with(slice_html)
        revision
      end
      it 'removes all newlines, whitespace and breaks from the html' do
        allow(CGI).to receive(:unescape_html).and_return(unescaped_html)
        expect(revision.revision_list).to eq(squished_html)
      end
      it 'returns an html_safe string' do
        expect(revision.revision_list.html_safe?).to be true
      end
    end
  end
end