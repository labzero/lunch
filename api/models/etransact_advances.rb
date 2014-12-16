module MAPI
  module Models
    class EtransactAdvances
      include Swagger::Blocks
      swagger_model :etransactAdvancesStatus do
        property :etransact_advances_status do
          key :type, :boolean
          key :description, 'indicate etransact advances is turn on and at least one proudct/term not reach End Time for today'
        end
        property :wl_vrc_status do
          key :type, :boolean
          key :description, 'indicate that wholeloan VRC overnight term is not disabled'
        end
      end
    end
  end
end