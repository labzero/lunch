require 'rails_helper'
require 'rake'

RSpec.describe Stats do
  describe '`extranet_logins` class method' do
    let(:service_object) { double(MembersService, all_members: [])}
    let(:request) { double(ActionDispatch::Request) }
    let(:call_method)  { subject.extranet_logins(request) }
    before do
      allow(MembersService).to receive(:new).and_return(service_object)
      allow_any_instance_of(User).to receive(:ldap_entry).and_return({})
    end
    it 'creates a MembersService object with the supplied request' do
      expect(MembersService).to receive(:new).with(request).and_return(service_object)
      call_method
    end
    it 'creates a MembersService object with a dummy request if none is supplied' do
      expect(MembersService).to receive(:new).with(kind_of(ActionDispatch::TestRequest)).and_return(service_object)
      subject.extranet_logins
    end
    it 'fetches all the members' do
      expect(service_object).to receive(:all_members).and_return([])
      call_method
    end
    it 'fetchs all users in the extranet domain with at least one login' do
      expect(User).to receive(:extranet_logins).and_return([])
      call_method
    end
    it 'returns a hash keyed by member bank names with a list of users for the values' do
      users = [
        FactoryGirl.build(:user, username: SecureRandom.hex),
        FactoryGirl.build(:user, username: SecureRandom.hex),
        FactoryGirl.build(:user, username: SecureRandom.hex)
      ]
      members = [
        {id: 1, name: SecureRandom.hex}.with_indifferent_access,
        {id: 2, name: SecureRandom.hex}.with_indifferent_access,
        {id: 3, name: SecureRandom.hex}.with_indifferent_access
      ]
      allow(users[0]).to receive(:member_id).and_return(1)
      allow(users[1]).to receive(:member_id).and_return(2)
      allow(users[2]).to receive(:member_id).and_return(1)
      allow(service_object).to receive(:all_members).and_return(members)
      allow(User).to receive(:extranet_logins).and_return(users)
      expect(call_method).to include({
        members[0][:name] => contain_exactly(users[0].username, users[2].username),
        members[1][:name] => contain_exactly(users[1].username)
      })
    end
    it 'returns the username in sorted order' do
      users = [
        FactoryGirl.build(:user, username: SecureRandom.hex),
        FactoryGirl.build(:user, username: SecureRandom.hex),
        FactoryGirl.build(:user, username: SecureRandom.hex)
      ]
      member = {id: 1, name: SecureRandom.hex}.with_indifferent_access
      usernames_sorted = users.collect(&:username).sort
      
      allow(service_object).to receive(:all_members).and_return([member])
      allow(User).to receive(:extranet_logins).and_return(users)
      users.each { |u| allow(u).to receive(:member_id).and_return(1) }

      expect(call_method[member[:name]]).to eq(usernames_sorted)
    end
    it 'puts users with an unknown member_id into their own group' do
      user = FactoryGirl.build(:user, username: SecureRandom.hex)
      allow(user).to receive(:member_id).and_return(nil)
      allow(User).to receive(:extranet_logins).and_return([user])
      expect(call_method[I18n.t('global.unknown')]).to eq([user.username])
    end
  end
end

RSpec.describe Rake do
  describe 'stats:extranet_logins' do
    let(:invoke_task) { Rake::Task['stats:extranet_logins'].invoke }
    before do
      Rake::Task.clear
      load 'lib/tasks/stats.rake'
      Rake::Task.define_task(:environment)
    end
    it 'calls Stats.extranet_logins' do
      expect(Stats).to receive(:extranet_logins).with(no_args).and_return({})
      invoke_task
    end
    it 'prints out the member and user names' do
      results = {
        SecureRandom.hex => [SecureRandom.hex, SecureRandom.hex].sort!,
        SecureRandom.hex => [SecureRandom.hex, SecureRandom.hex].sort!
      }
      allow(Stats).to receive(:extranet_logins).with(no_args).and_return(results)

      desired_output = ""
      results.each do |member, users|
        desired_output = desired_output + "#{member}:\n\n#{users.join("\n")}\n\n"
      end
      expect{invoke_task}.to output(desired_output).to_stdout
    end

  end
end