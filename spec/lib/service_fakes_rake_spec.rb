require 'rails_helper'
require 'rake'
require 'fhlb_member/services/fakes'

describe Rake do
  before :each do
    Rake::Task.clear
    load 'lib/tasks/service_fakes.rake'
    allow(FhlbMember::Services::Fakes).to receive(:use_fake_service).and_return(true)
  end

  describe 'the `service_fakes:enable` task' do
    let(:run_task) { Rake::Task['service_fakes:enable'].invoke }
    [:mds, :cal, :pi].each do |service|
      it "enables the fake #{service} service" do
        expect(FhlbMember::Services::Fakes).to receive(:use_fake_service).with(service, true)
        run_task
      end
    end
  end
  describe 'the `service_fakes:disable` task' do
    let(:run_task) { Rake::Task['service_fakes:disable'].invoke }
    [:mds, :cal, :pi].each do |service|
      it "disables the fake #{service} service" do
        expect(FhlbMember::Services::Fakes).to receive(:use_fake_service).with(service, false)
        run_task
      end
    end
  end
  [:enable, :disable].each do |switch|
    [:mds, :cal, :pi].each do |service|
      describe "the `service_fakes:#{service}:#{switch}` task" do
        let(:run_task) { Rake::Task["service_fakes:#{service}:#{switch}"].invoke }
        it "calls `FhlbMember::Services::Fakes.use_fake_service` with `#{service}`" do
          expect(FhlbMember::Services::Fakes).to receive(:use_fake_service).with(service, anything)
          run_task
        end
        it "calls `FhlbMember::Services::Fakes.use_fake_service` with `#{switch == :enable}`" do
          expect(FhlbMember::Services::Fakes).to receive(:use_fake_service).with(anything, switch == :enable)
          run_task
        end
        it 'raises an error if `FhlbMember::Services::Fakes.use_fake_service` returns false' do
          allow(FhlbMember::Services::Fakes).to receive(:use_fake_service).and_return(false)
          expect{run_task}.to raise_error
        end
      end
    end
  end
end