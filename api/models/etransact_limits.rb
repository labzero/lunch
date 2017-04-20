module MAPI
  module Models
    class EtransactLimitsArray
      include Swagger::Blocks
      swagger_model :EtransactLimitsArray do
        key :required, [:term, :ao_term_bucket_id, :whole_loan_enabled, :sbc_agency_enabled, :sbc_aaa_enabled, :sbc_aa_enabled,
                        :low_days_to_maturity, :high_days_to_maturity, :min_online_advance, :term_daily_limit, :product_type,
                        :end_time, :override_end_date, :override_end_time]
        property :term do
          key :type, :string
          key :description, 'The term for the given bucket'
          key :notes, "Possible values: [:open, :'1week', :'2week', :'3week', :'1month', :'2month', :'3month', :'6month', :'9month', :'12month', :'1year', :'2year', :'3year']"
        end
        property :ao_term_bucket_id do
          key :type, :integer
          key :description, 'The primary key used by FHLB to map to different term buckets.'
        end
        property :whole_loan_enabled do
          key :type, :string
          key :description, 'Indicates whether whole loans are enabled for the bucket via the characters Y or N'
        end
        property :sbc_agency_enabled do
          key :type, :string
          key :description, 'Indicates whether sbc agency loans are enabled for the bucket via the characters Y or N'
        end
        property :sbc_aaa_enabled do
          key :type, :string
          key :description, 'Indicates whether sbc aaa loans are enabled for the bucket via the characters Y or N'
        end
        property :sbc_aa_enabled do
          key :type, :string
          key :description, 'Indicates whether sbc aa loans are enabled for the bucket via the characters Y or N'
        end
        property :low_days_to_maturity do
          key :type, :integer
          key :description, 'The lower end of the maturity window to which this term bucket applies, given in days'
        end
        property :high_days_to_maturity do
          key :type, :integer
          key :description, 'The higher end of the maturity window to which this term bucket applies, given in days'
        end
        property :min_online_advance do
          key :type, :integer
          key :description, 'The minimum advance dollar value allowed to be made online for this term bucket'
        end
        property :term_daily_limit do
          key :type, :integer
          key :description, 'The maximum amount allowed to be traded online in a given day for this term bucket'
        end
        property :product_type do
          key :type, :string
          key :description, 'Indicates if the term bucket is fixed-rate or variable-rate via the characters FRC or VRC'
        end
        property :end_time do
          key :type, :string
          key :description, 'A 4-character string corresponding to the time of day the bucket will shut off. Values from `0000` to `2400`'
        end
        property :override_end_date do
          key :type, :string
          key :format, :date
          key :description, 'The date the override time applies to'
        end
        property :override_end_time do
          key :type, :string
          key :description, 'A 4-character string corresponding to the override time of day the bucket will shut off. Values from `0000` to `2400`'
        end
      end
    end
    class EtransactLimitsHash
      include Swagger::Blocks
      swagger_model :EtransactLimitsHash do
        [:open, :'1week', :'2week', :'3week', :'1month', :'2month', :'3month', :'6month', :'9month', :'12month', :'1year', :'2year', :'3year'].each do |term|
          property term do
            key :required, true
            key :type, :EtransactLimitsBucket
            key :description, "An object containing the limit information for the `#{term}` term"
          end
        end
      end
      swagger_model :EtransactLimitsBucket do
        property :whole_loan_enabled do
          key :type, :string
          key :description, 'Indicates whether whole loans are enabled for the bucket via the characters Y or N'
        end
        property :sbc_agency_enabled do
          key :type, :string
          key :description, 'Indicates whether sbc agency loans are enabled for the bucket via the characters Y or N'
        end
        property :sbc_aaa_enabled do
          key :type, :string
          key :description, 'Indicates whether sbc aaa loans are enabled for the bucket via the characters Y or N'
        end
        property :sbc_aa_enabled do
          key :type, :string
          key :description, 'Indicates whether sbc aa loans are enabled for the bucket via the characters Y or N'
        end
        property :low_days_to_maturity do
          key :type, :integer
          key :description, 'The lower end of the maturity window to which this term bucket applies, given in days'
        end
        property :high_days_to_maturity do
          key :type, :integer
          key :description, 'The higher end of the maturity window to which this term bucket applies, given in days'
        end
        property :min_online_advance do
          key :type, :integer
          key :description, 'The minimum advance dollar value allowed to be made online for this term bucket'
        end
        property :term_daily_limit do
          key :type, :integer
          key :description, 'The maximum amount allowed to be traded online in a given day for this term bucket'
        end
        property :product_type do
          key :type, :string
          key :description, 'Indicates if the term bucket is fixed-rate or variable-rate via the characters FRC or VRC'
        end
        property :end_time do
          key :type, :string
          key :description, 'A 4-character string corresponding to the time of day the bucket will shut off. Values from `0000` to `2400`'
        end
        property :override_end_date do
          key :type, :string
          key :format, :date
          key :description, 'The date the override time applies to'
        end
        property :override_end_time do
          key :type, :string
          key :description, 'A 4-character string corresponding to the override time of day the bucket will shut off. Values from `0000` to `2400`'
        end
      end
    end
  end
end