require 'rails_helper'
require 'rake'
require 'flipper/adapters/memory'

describe Rake do
  let(:flipper) { Rails.application.flipper }
  let(:features) { ['foo', 'bar'] }
  before do
    Rake::Task.clear
    load 'lib/tasks/flipper.rake'
    Rake::Task.define_task(:environment)
    Rails.application.flipper = Flipper.new(Flipper::Adapters::Memory.new)
  end

  describe 'the flipper:seed task' do
    let(:file_path) { double('A File Path') }
    let(:run_task) { Rake::Task['flipper:seed'].invoke(file_path) }
    before do
      allow(File).to receive(:read).with(file_path).and_return(features.to_json)
    end
    it 'removes features not found in the supplied list' do
      flipper['woo'].disable
      flipper['too'].disable
      run_task
      expect(flipper.features.collect(&:name)).to_not include('woo', 'too')
    end
    it 'adds features found in the supplied list if they are missing' do
      run_task
      expect(flipper.features.collect(&:name)).to include(*features)
    end
    it 'adds features in the disabled state' do
      run_task
      expect(flipper.features.collect(&:enabled?)).to eq([false, false])
    end
    it 'does nothing to a feature that already exists which is also in the list' do
      features.each do |name|
        flipper[name].enable
      end
      run_task
      expect(flipper.features.collect(&:enabled?)).to eq([true, true])
    end
    it 'uses the list in `db/features.json` if a file path is not supplied' do
      expect(File).to receive(:read).with(Rails.root.join('db', 'features.json')).and_return('[]')
      Rake::Task['flipper:seed'].invoke
    end
  end

  context do
    let(:feature) { SecureRandom.hex }
    let(:actor) { double('An Actor', flipper_id: SecureRandom.hex) }
    let(:other_actor) { double('Another Actor', flipper_id: SecureRandom.hex) }

    describe 'the flipper:feature:enable task' do
      let(:task) { Rake::Task['flipper:feature:enable'] }

      it 'raises an error if called without a feature' do
        expect {task.invoke}.to raise_error(ArgumentError)
      end
      it 'enables the feature for all actors if none is provided' do
        task.invoke(feature)
        expect(flipper[feature].enabled?).to be(true)
      end
      it 'enables the feature for just the supplied actor if one is provided' do
        task.invoke(feature, actor)
        expect(flipper[feature].enabled?).to be(false)
        expect(flipper[feature].enabled?(actor)).to be(true)
      end
      it 'wraps the supplied actor with FlipperActor.wrap' do
        expect(FhlbMember::FlipperActor).to receive(:wrap).with(actor)
        task.invoke(feature, actor)
      end
    end

    describe 'the flipper:feature:enable_all task' do
      let(:task) { Rake::Task['flipper:feature:enable_all'] }

      it 'raises an error if called without an actor' do
        expect {task.invoke}.to raise_error(ArgumentError)
      end
      it 'enables all known features for the supplied actor' do
        features.each do |feature|
          flipper[feature].disable
        end
        task.invoke(actor)
        features.each do |feature|
          expect(flipper[feature].enabled?).to be(false)
          expect(flipper[feature].enabled?(actor)).to be(true)
        end
      end
      it 'wraps the supplied actor with FlipperActor.wrap' do
        expect(FhlbMember::FlipperActor).to receive(:wrap).with(actor)
        task.invoke(actor)
      end
    end

    describe 'the flipper:feature:disable task' do
      let(:task) { Rake::Task['flipper:feature:disable'] }
      before do
        flipper[feature].enable
      end

      it 'raises an error if called without a feature' do
        expect {task.invoke}.to raise_error(ArgumentError)
      end
      it 'disables the feature for all actors if none is provided' do
        task.invoke(feature)
        expect(flipper[feature].enabled?).to be(false)
      end
      it 'disables the feature for just the supplied actor if one is provided' do
        flipper[feature].disable
        flipper[feature].enable(actor)
        flipper[feature].enable(other_actor)
        task.invoke(feature, actor)
        expect(flipper[feature].enabled?(other_actor)).to be(true)
        expect(flipper[feature].enabled?(actor)).to be(false)
      end
      it 'wraps the supplied actor with FlipperActor.wrap' do
        expect(FhlbMember::FlipperActor).to receive(:wrap).with(actor)
        task.invoke(feature, actor)
      end
    end

    describe 'the flipper:feature:disable_all task' do
      let(:task) { Rake::Task['flipper:feature:disable_all'] }

      it 'raises an error if called without an actor' do
        expect {task.invoke}.to raise_error(ArgumentError)
      end
      it 'disables all known features for the supplied actor' do
        features.each do |feature|
          flipper[feature].disable
          flipper[feature].enable(actor)
          flipper[feature].enable(other_actor)
        end
        task.invoke(actor)
        features.each do |feature|
          expect(flipper[feature].enabled?(other_actor)).to be(true)
          expect(flipper[feature].enabled?(actor)).to be(false)
        end
      end
      it 'wraps the supplied actor with FlipperActor.wrap' do
        expect(FhlbMember::FlipperActor).to receive(:wrap).with(actor)
        task.invoke(actor)
      end
    end
  end
end