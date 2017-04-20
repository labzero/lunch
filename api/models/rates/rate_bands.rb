module MAPI
  module Models
    class RateBands
      include Swagger::Blocks
      swagger_model :RateBands do
        [:overnight, :"1week", :"2week", :"3week", :"1month", :"2month", :"3month", :"6month", :"1year", :"2year", :"3year"].each do |term|
          property term do
            key :required, true
            key :descriptions, "The rate band info for the #{term} term"
            key :type, :RateBandObject
          end
        end
      end
      swagger_model :RateBandObject do
        property :'FOBO_TERM_FREQUENCY' do
          key :required, true
          key :type, :integer
          key :description, 'An integer value corresponding to the number of `FOBO_TERM_UNIT`s for this term'
        end
        property :'FOBO_TERM_UNIT' do
          key :required, true
          key :type, :string
          key :description, 'A one-character description of the term units'
          key :notes, 'D = Days, W = Weeks, M = Months, Y = Years'
        end
        property :'LOW_BAND_OFF_BP' do
          key :required, true
          key :type, :integer
          key :description, 'The number of basis points past which the rate will be shut off, on the low end'
        end
        property :'LOW_BAND_WARN_BP' do
          key :required, true
          key :type, :integer
          key :description, 'The number of basis points past which the rate will issue a warning, on the low end'
        end
        property :'HIGH_BAND_OFF_BP' do
          key :required, true
          key :type, :integer
          key :description, 'The number of basis points past which the rate will be shut off, on the high end'
        end
        property :'HIGH_BAND_WARN_BP' do
          key :required, true
          key :type, :integer
          key :description, 'The number of basis points past which the rate will issue a warning, on the high end'
        end
      end
    end
  end
end
