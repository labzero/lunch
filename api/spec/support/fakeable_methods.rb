module FakeableMAPIMethod
  def fakeable_method(description, *metadata, &block)
    shared_context 'paths independent of environment', &block
    describe description, *metadata do
      [:development, :test, :production].each do |environment|
        describe "in the #{environment} environment" do
          let(:app) { double(Sinatra::Base) }
          let(:environment) { environment }
          before do
            allow(app).to receive_message_chain(:settings, :environment).and_return(environment)
            allow(app).to receive(:environment).and_return(environment)
          end
          include_context 'paths independent of environment'
          if production_environments.include?(environment)
            context nil, *production_metadata, &production_only if production_only
          else
            context nil, *excluding_production_metadata, &excluding_production if excluding_production
          end
        end
      end
    end
  end

  def production_environments(*environments)
    @production_environments = environments if environments.present?
    @production_environments ||= [:production]
    @production_environments
  end

  def production_only(*metadata, &block)
    production_metadata(*metadata)
    @production_only = block if block
    @production_only
  end

  def production_metadata(*metadata)
    @production_metadata = metadata if metadata.present?
    @production_metadata ||= []
    @production_metadata
  end

  def excluding_production_metadata(*metadata)
    @excluding_production_metadata = metadata if metadata.present?
    @excluding_production_metadata ||= []
    @excluding_production_metadata
  end

  def excluding_production(*metadata, &block)
    excluding_production_metadata(*metadata)
    @excluding_production = block if block
    @excluding_production
  end
end

RSpec.configure do |config|
  config.extend FakeableMAPIMethod
end