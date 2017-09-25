require 'rails_helper'

RSpec.describe MortgagesController, :type => :controller do
  login_user

  let(:member_id) { double('A Member ID') }

  before { allow(controller).to receive(:current_member_id).and_return(member_id) }

  shared_examples 'a MortgagesController action that sets page-specific instance variables with a before filter' do
    it 'sets the active nav to `:mortgages`' do
      expect(controller).to receive(:set_active_nav).with(:mortgages)
      call_action
    end
    it 'sets the `@html_class` to `white-background` if no class has been set' do
      call_action
      expect(assigns[:html_class]).to eq('white-background')
    end
    it 'does not set `@html_class` if it has already been set' do
      html_class = instance_double(String)
      controller.instance_variable_set(:@html_class, html_class)
      call_action
      expect(assigns[:html_class]).to eq(html_class)
    end
  end

  RSpec.shared_examples 'it checks the `request?` `mortgage` policy' do
    before { allow(subject).to receive(:authorize).and_call_original }
    it 'checks if the current user is allowed to edit trade rules' do
      expect(subject).to receive(:authorize).with(:mortgage, :request?)
      call_action
    end
    it 'raises any errors raised by checking to see if the user is authorized to modify the advance' do
      error = Pundit::NotAuthorizedError
      allow(subject).to receive(:authorize).and_raise(error)
      expect{call_action}.to raise_error(error)
    end
  end

  describe 'get `new`' do
    allow_policy :mortgage, :request?

    let(:today) { Time.zone.today }
    let(:call_action) { get :new }
    before { allow(Time.zone).to receive(:today).and_return(today) }

    it_behaves_like 'a MortgagesController action that sets page-specific instance variables with a before filter'
    it_behaves_like 'it checks the `request?` `mortgage` policy'
    it 'sets the `@title`' do
      call_action
      expect(assigns[:title]).to eq(I18n.t('mortgages.new.title'))
    end
    it 'sets `@due_datetime` to a day one week from today, at 5pm' do
      call_action
      expect(assigns[:due_datetime]).to eq(Time.zone.parse("#{(today + 7.days).iso8601} 17:00:00"))
    end
    it 'sets `@extension_datetime` to a day two weeks from today, at 5pm' do
      call_action
      expect(assigns[:extension_datetime]).to eq(Time.zone.parse("#{(today + 14.days).iso8601} 17:00:00"))
    end
    it 'sets `@pledge_type_dropdown_options` to the `PLEDGE_TYPE_DROPDOWN` constant' do
      call_action
      expect(assigns[:pledge_type_dropdown_options]).to eq(described_class::PLEDGE_TYPE_DROPDOWN)
    end
    it 'sets `@mcu_type_dropdown_options` to the `MCU_TYPE_DROPDOWN` constant' do
      call_action
      expect(assigns[:mcu_type_dropdown_options]).to eq(described_class::MCU_TYPE_DROPDOWN)
    end
    it 'sets `@program_type_dropdown_options` to the `PROGRAM_TYPE_DROPDOWN` constant' do
      call_action
      expect(assigns[:program_type_dropdown_options]).to eq(described_class::PROGRAM_TYPE_DROPDOWN)
    end
    it 'sets `@accepted_upload_mimetypes` to the joined `ACCEPTED_UPLOAD_MIMETYPES` constant' do
      call_action
      expect(assigns[:accepted_upload_mimetypes]).to eq(described_class::ACCEPTED_UPLOAD_MIMETYPES.join(', '))
    end
    it 'sets `@session_elevated` to the result of `session_elevated?`' do
      session_elevated = double('session info')
      allow(controller).to receive(:session_elevated?).and_return(session_elevated)
      call_action
      expect(assigns[:session_elevated]).to eq(session_elevated)
    end
  end
end