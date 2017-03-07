require 'rails_helper'

RSpec.describe RenderLetterOfCreditPDFJob, type: :job do
  it_behaves_like 'a job that initializes a controller', LettersOfCreditController

  it 'inherits from `RenderPDFJob`' do
    expect(described_class.superclass).to eq(RenderPDFJob)
  end
end