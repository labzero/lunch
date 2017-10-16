require 'rails_helper'

describe ContentManagementService do
  let(:member_id) { double('a member id') }
  let(:request) { ActionDispatch::TestRequest.new }
  let(:api) { instance_double(Prismic::API, get_by_uid: nil) }
  let(:url) { double('the prismic url') }
  let(:access_token) { double('the prismic access token') }
  let(:ref) { double('some ref') }
  let(:guide_type) { described_class::DOCUMENT_MAPPING.keys.sample }

  before do
    allow(Prismic).to receive(:api).and_return(api)
  end

  subject { ContentManagementService.new(member_id, request) }

  describe 'initialization' do
    it 'has a readable `member_id` attribute' do
      expect(subject.member_id).to eq(member_id)
    end
    it 'has a readable `request` attribute' do
      expect(subject.request).to eq(request)
    end
    it 'creates a new `Prismic::API` instance with the results of the `url` method' do
      allow_any_instance_of(described_class).to receive(:url).and_return(url)
      expect(Prismic).to receive(:api).with(url, anything)
      ContentManagementService.new(member_id, request)
    end
    it 'creates a new `Prismic::API` instance with the results of the `access_token` method' do
      allow_any_instance_of(described_class).to receive(:access_token).and_return(access_token)
      expect(Prismic).to receive(:api).with(anything, access_token)
      ContentManagementService.new(member_id, request)
    end
    it 'sets the readable `api` attribute to the instance of the `Prismic::API`' do
      expect(subject.api).to eq(api)
    end
  end

  describe 'instance methods' do
    describe '`get_document`' do
      let(:results) { double('some results') }
      let(:call_method) { subject.get_document(guide_type) }
      before { allow(subject).to receive(:ref).and_return(ref) }

      it 'raises an error if passed an invalid `cms_key`' do
        expect{subject.get_document(:foo)}.to raise_error(ArgumentError, 'Invalid `cms_key`')
      end
      it 'retrieves its `ref`' do
        expect(subject).to receive(:ref)
        call_method
      end
      it 'calls `get_by_uid` on its api with the `type` for the `cms_key`' do
        expect(subject.api).to receive(:get_by_uid).with(described_class::DOCUMENT_MAPPING[guide_type][:type], any_args)
        call_method
      end
      it 'calls `get_by_uid` on its api with the `uid` for the `cms_key`' do
        expect(subject.api).to receive(:get_by_uid).with(anything, described_class::DOCUMENT_MAPPING[guide_type][:uid], anything)
        call_method
      end
      it 'calls `get_by_uid` on its api with the `ref`' do
        expect(subject.api).to receive(:get_by_uid).with(anything, anything, ref: ref)
        call_method
      end
      it 'returns the results of calling `get_by_uid`' do
        allow(subject.api).to receive(:get_by_uid).and_return(results)
        expect(call_method).to eq(results)
      end
      context 'when a `Prismic::Error` is raised' do
        let(:error) { Prismic::Error.new }
        before do
          allow(subject.api).to receive(:get_by_uid).and_raise(error)
          allow(Rails.logger).to receive(:error)
        end
        it 'returns nil' do
          expect(call_method).to be nil
        end
        it 'logs information about the error' do
          expect(Rails.logger).to receive(:error).with("Prismic CMS error for fhlb_id `#{member_id}`, request_uuid `#{request.try(:uuid)}`: #{error.class.name}")
          call_method
        end
      end
    end

    describe '`get_pdf_url`' do
      let(:pdf_fragment) { instance_double(Prismic::Fragments::FileLink)  }
      let(:fragments) {{'pdf' => pdf_fragment}}
      let(:document) { instance_double(Prismic::Document, fragments: nil) }
      let(:call_method) { subject.get_pdf_url(guide_type) }

      it 'calls `get_document` with the `cms_key`' do
        expect(subject).to receive(:get_document).with(guide_type)
        call_method
      end
      context 'when no content is returned from `get_document`' do
        before { allow(subject).to receive(:get_document) }

        it 'returns nil' do
          expect(call_method).to be nil
        end
      end
      context 'when content is returned from `get_document`' do
        before { allow(subject).to receive(:get_document).and_return(document) }

        it 'retrieves the fragments hash from the returned content' do
          expect(document).to receive(:fragments)
          call_method
        end

        context 'when there are no fragments' do
          it 'returns nil' do
            expect(call_method).to be nil
          end
        end
        context 'when fragments are returned with a `pdf` key' do
          before { allow(document).to receive(:fragments).and_return(fragments) }

          it 'returns the `url` of the pdf fragment' do
            allow(pdf_fragment).to receive(:url).and_return(url)
            expect(call_method).to eq(url)
          end
        end
        context 'when fragments are returned that do not have a `pdf` key' do
          before { allow(document).to receive(:fragments).and_return({'foo' => pdf_fragment}) }

          it 'returns nil' do
            expect(call_method).to be nil
          end
        end
      end
    end

    describe '`get_slices_by_type`' do
      let(:slice_type) { SecureRandom.hex }
      let(:matching_slice_1) { instance_double(Prismic::Fragments::CompositeSlice, slice_type: slice_type) }
      let(:unmatching_slice) { instance_double(Prismic::Fragments::CompositeSlice, slice_type: slice_type + 'foo') }
      let(:matching_slice_2) { instance_double(Prismic::Fragments::CompositeSlice, slice_type: slice_type) }
      let(:slice_zone) { instance_double(Prismic::Fragments::SliceZone, slices: []) }
      let(:document) { instance_double(Prismic::Document, get_slice_zone: slice_zone) }
      let(:call_method) { subject.get_slices_by_type(guide_type, slice_type) }

      it 'calls `get_document` with the `cms_key`' do
        expect(subject).to receive(:get_document).with(guide_type)
        call_method
      end
      context 'when no content is returned from `get_document`' do
        before { allow(subject).to receive(:get_document) }

        it 'returns nil' do
          expect(call_method).to be nil
        end
      end
      context 'when content is returned from `get_document`' do
        before { allow(subject).to receive(:get_document).and_return(document) }

        it 'calls `get_slice_zone` on the returned document with a string containing the `type` of the `cms_key`' do
          expect(document).to receive(:get_slice_zone).with("#{described_class::DOCUMENT_MAPPING[guide_type][:type]}.body").and_return(slice_zone)
          call_method
        end
        it 'returns an array of slices with a `slice_type` matching the passed `slice_type` arg' do
          allow(slice_zone).to receive(:slices).and_return([matching_slice_1, unmatching_slice, matching_slice_2])
          expect(call_method).to eq([matching_slice_1, matching_slice_2])
        end
      end
    end

    describe '`get_date`' do
      let(:date_field) { SecureRandom.hex }
      let(:document) { instance_double(Prismic::Document, get_date: nil) }
      let(:date) { Time.zone.today - rand(1..360).days }
      let(:date_node) { double('node', value: date) }
      let(:call_method) { subject.get_date(guide_type, date_field) }

      it 'calls `get_document` with the `cms_key`' do
        expect(subject).to receive(:get_document).with(guide_type)
        call_method
      end
      context 'when no content is returned from `get_document`' do
        before { allow(subject).to receive(:get_document) }

        it 'returns nil' do
          expect(call_method).to be nil
        end
      end
      context 'when content is returned from `get_document`' do
        before { allow(subject).to receive(:get_document).and_return(document) }

        it 'calls `get_date` on the returned document with a string containing the `type` of the `cms_key` and the `date_field` arg' do
          expect(document).to receive(:get_date).with("#{described_class::DOCUMENT_MAPPING[guide_type][:type]}.#{date_field}")
          call_method
        end
        it 'returns the `value` of the node returned by `get_date`' do
          allow(document).to receive(:get_date).and_return(date_node)
          expect(call_method).to eq(date_node.value)
        end
        it 'ensures that a date is returned' do
          date_string = date.iso8601
          allow(document).to receive(:get_date).and_return(date_node)
          allow(date_node).to receive(:value).and_return(date_string)
          expect(call_method).to eq(date)
        end
      end
    end
  end

  describe 'private methods' do
    describe '`access_token`' do
      let(:access_token) { instance_double(String) }
      let(:env_access_token) { SecureRandom.hex }
      let(:call_method) { subject.send(:access_token) }

      it 'returns the attribute `@access_token` if it is already assigned' do
        subject.instance_variable_set(:@access_token, access_token)
        expect(call_method).to eq(access_token)
      end
      context 'when the `@access_token` attribute has not already been assigned' do
        it 'returns the `PRISMIC_ACCESS_TOKEN` environment variable if it exists' do
          cached_access_token = ENV['PRISMIC_ACCESS_TOKEN']
          ENV['PRISMIC_ACCESS_TOKEN'] = env_access_token
          expect(call_method).to eq(env_access_token)
          ENV['PRISMIC_ACCESS_TOKEN'] = cached_access_token
        end
        it 'returns the `token` from the `config` if there is no `PRISMIC_ACCESS_TOKEN` environment variable' do
          subject.instance_variable_set(:@access_token, nil)
          cached_access_token = ENV['PRISMIC_ACCESS_TOKEN']
          ENV['PRISMIC_ACCESS_TOKEN'] = nil
          expect(subject).to receive(:config).and_return({'token' => access_token})
          expect(call_method).to eq(access_token)
          ENV['PRISMIC_ACCESS_TOKEN'] = cached_access_token
        end
      end
    end

    describe '`config`' do
      let(:results) { double('some results', :[] => nil) }
      let(:call_method) { subject.send(:config) }

      context 'when the `@config` attribute already exists' do
        let(:existing_config) { double('some config')}
        before { subject.instance_variable_set(:@config, existing_config) }

        it 'returns the existing config' do
          expect(call_method).to eq(existing_config)
        end
      end
      context 'when the `@config` attribute does not yet exist' do
        before { subject.instance_variable_set(:@config, nil) }

        it 'loads the "config/prismic.yml" YAML file' do
          expect(YAML).to receive(:load).with(ERB.new(File.new(Rails.root + "config/prismic.yml").read).result)
          call_method
        end
        it 'returns the loaded YAML file' do
          allow(YAML).to receive(:load).and_return(results)
          expect(call_method).to eq(results)
        end
      end
    end

    describe '`ref`' do
      let(:ref) { instance_double(String) }
      let(:ref_object) { instance_double(Prismic::Ref, ref: nil) }
      let(:call_method) { subject.send(:ref) }
      before do
        allow(subject.api).to receive(:ref)
        allow(subject.api).to receive(:master).and_return(ref_object)
      end

      context 'when the `@ref` attribute already exists' do
        let(:existing_ref) { double('some ref')}
        before { subject.instance_variable_set(:@ref, existing_ref) }

        it 'returns the existing ref' do
          expect(call_method).to eq(existing_ref)
        end
      end
      context 'when the `@ref` attribute does not yet exist' do
        let(:master_ref) { instance_double(String) }
        before { subject.instance_variable_set(:@ref, nil) }

        context 'when there is a `PRISMIC_REF` environment variable' do
          let(:fetched_ref) { instance_double(String) }
          let(:env_ref) { SecureRandom.hex }

          it 'fetches the ref from the api' do
            cached_ref = ENV['PRISMIC_REF']
            ENV['PRISMIC_REF'] = env_ref
            expect(subject.api).to receive(:ref).with(env_ref).and_return(ref_object)
            call_method
            ENV['PRISMIC_REF'] = cached_ref
          end

          context 'when the `PRISMIC_REF` is a valid ref that exists in the Prismic repo' do
            it 'returns the result of calling `ref` on the returned object' do
              cached_ref = ENV['PRISMIC_REF']
              ENV['PRISMIC_REF'] = env_ref
              allow(subject.api).to receive(:ref).with(env_ref).and_return(ref_object)
              allow(ref_object).to receive(:ref).and_return(fetched_ref)
              expect(call_method).to eq(fetched_ref)
              ENV['PRISMIC_REF'] = cached_ref
            end
          end
          context 'when the `PRISMIC_REF` is a not a valid ref and does not exist in the Prismic repo' do
            it 'calls `master` on the api object' do
              cached_ref = ENV['PRISMIC_REF']
              ENV['PRISMIC_REF'] = env_ref
              allow(subject.api).to receive(:ref).with(env_ref).and_return(nil)
              expect(subject.api).to receive(:master).and_return(ref_object)
              call_method
              ENV['PRISMIC_REF'] = cached_ref
            end
            it 'returns the result of calling `ref` on the returned master object' do
              cached_ref = ENV['PRISMIC_REF']
              ENV['PRISMIC_REF'] = env_ref
              allow(subject.api).to receive(:ref).with(env_ref).and_return(nil)
              allow(subject.api).to receive(:master).and_return(ref_object)
              allow(ref_object).to receive(:ref).and_return(master_ref)
              expect(call_method).to eq(master_ref)
              ENV['PRISMIC_REF'] = cached_ref
            end
          end
        end

        context 'when there is not a `PRISMIC_REF` environment variable' do
          it 'calls `master` on the api object' do
            cached_ref = ENV['PRISMIC_REF']
            ENV['PRISMIC_REF'] = nil
            expect(subject.api).to receive(:master).and_return(ref_object)
            call_method
            ENV['PRISMIC_REF'] = cached_ref
          end
          it 'returns the result of calling `ref` on the returned master object' do
            cached_ref = ENV['PRISMIC_REF']
            ENV['PRISMIC_REF'] = nil
            allow(ref_object).to receive(:ref).and_return(master_ref)
            expect(call_method).to eq(master_ref)
            ENV['PRISMIC_REF'] = cached_ref
          end
        end
      end
    end

    describe '`url`' do
      let(:url) { instance_double(String) }
      let(:env_url) { SecureRandom.hex }
      let(:call_method) { subject.send(:url) }

      it 'returns the attribute `@url` if it is already assigned' do
        subject.instance_variable_set(:@url, url)
        expect(call_method).to eq(url)
      end
      context 'when the `@url` attribute has not already been assigned' do
        before { subject.instance_variable_set(:@url, nil) }

        it 'returns the `PRISMIC_URL` environment variable if it exists' do
          cached_url = ENV['PRISMIC_URL']
          ENV['PRISMIC_URL'] = env_url
          expect(call_method).to eq(env_url)
          ENV['PRISMIC_URL'] = cached_url
        end
        it 'returns the `url` from the `config` if there is no `PRISMIC_URL` environment variable' do
          cached_url = ENV['PRISMIC_URL']
          ENV['PRISMIC_URL'] = nil
          expect(subject).to receive(:config).and_return({'url' => url})
          expect(call_method).to eq(url)
          ENV['PRISMIC_URL'] = cached_url
        end
      end
    end
  end
end
