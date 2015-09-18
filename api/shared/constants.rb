require 'active_support/core_ext/hash/indifferent_access'

module MAPI
  module Shared
    module Constants
      SOAP_HEADER = {'wsse:Security' => {'wsse:UsernameToken' => {'wsse:Username' => ENV['MAPI_FHLBSF_ACCOUNT'], 'wsse:Password' => ENV['SOAP_SECRET_KEY']}}}
      COMMON = { env_namespace: :soapenv, element_form_default: :qualified, namespace_identifier: :v1, pretty_print_xml: true }

      COLLATERAL_TYPES = [:standard, :sbc]
      COLLATERAL_MAPPING = {
          standard: 'REGULAR',
          sbc: 'CREDIT'
      }.with_indifferent_access
      CREDIT_TYPES = [:frc, :vrc, :'1m_libor', :'3m_libor', :'6m_libor', :daily_prime, :embedded_cap]

      CURRENT_CREDIT_TYPES = [:vrc, :frc, :arc]
      CURRENT_CREDIT_MAPPING = {
          vrc: 'VARIABLES',
          frc: 'FIXED',
          arc: 'ADJUSTABLES'
      }.with_indifferent_access

      LOAN_TYPES = [:whole, :agency, :aaa, :aa]
      LOAN_TERMS = [:overnight, :open, :'1week', :'2week', :'3week', :'1month', :'2month', :'3month', :'6month', :'1year', :'2year', :'3year']
      LOAN_MAPPING = {
          whole: 'FRC_WL',
          agency: 'FRC_AGCY',
          aaa: 'FRC_AAA',
          aa: 'FRC_AA'
      }.with_indifferent_access

        LOAN_MAPPING_INVERTED = LOAN_MAPPING.invert.with_indifferent_access

      TERM_MAPPING = {
          :overnight => {
              frequency: '1',
              frequency_unit: 'D',
          },
          :open => {
              frequency: '1',
              frequency_unit: 'D'
          },
          :'1week'=> {
              frequency: '1',
              frequency_unit: 'W'
          },
          :'2week'=> {
              frequency: '2',
              frequency_unit: 'W'
          },
          :'3week'=> {
              frequency: '3',
              frequency_unit: 'W'
          },
          :'1month'=> {
              frequency: '1',
              frequency_unit: 'M'
          },
          :'2month'=> {
              frequency: '2',
              frequency_unit: 'M'
          },
          :'3month'=> {
              frequency: '3',
              frequency_unit: 'M'
          },
          :'6month'=> {
              frequency: '6',
              frequency_unit: 'M'
          },
          :'1year'=> {
              frequency: '1',
              frequency_unit: 'Y'
          },
          :'2year'=> {
              frequency: '2',
              frequency_unit: 'Y'
          },
          :'3year'=> {
              frequency: '3',
              frequency_unit: 'Y'
          }
      }.with_indifferent_access

      def self.invert_term_mapping( mapping )
        mapping.each_with_object({}) do |(term, v), h|
          (h["#{v[:frequency]}#{v[:frequency_unit]}"] ||= []) << term
        end.with_indifferent_access
      end

      FREQUENCY_MAPPING = invert_term_mapping( TERM_MAPPING )

      VRC_TERMS = ['1D']
      FRC_TERMS = ['1M', '2M', '3M', '6M', '1Y', '2Y', '3Y', '5Y', '7Y', '10Y', '15Y', '20Y', '30Y']
      LIBOR_TERMS = ['1Y', '2Y', '3Y', '5Y']
      REPORT_PARAM_DATE_FORMAT = /\A\d\d\d\d-(0\d|1[012])-([0-2]\d|3[01])\Z/
      INDEX_CREDIT_TYPES = [:vrc, :frc]
      BASIS_POINT_CREDIT_TYPES = [:'1m_libor', :'3m_libor', :'6m_libor']
      DAILY_PRIME_TRX_IR_CODE_INDEX = 'PRIME'
      DAILY_PRIME_TRX_IR_CODE_BASIS_POINT = 'APRIMEAT'
      COF_TYPES = %w(COF_FIXED COF_3L ADVANCE_BENCHMARK MU_WL MU_AGCY MU_AA MU_AAA)

      IRDB_CODE_TERM_MAPPING =
        {:standard => {
          :vrc => {
            code:'FRADVN',
            terms: VRC_TERMS,
            min_date: '2002-02-28'.to_date
          },
          :frc => {
            code: 'FRADVN',
            terms: FRC_TERMS,
            min_date: '1993-02-16'.to_date
          },
          :'1m_libor' => {
            code: 'LARC1M',
            terms: LIBOR_TERMS,
            min_date: '1997-05-07'.to_date
          },
          :'3m_libor' => {
            code: 'LARC3M',
            terms: LIBOR_TERMS,
            min_date: '1997-05-07'.to_date
          },
          :'6m_libor' => {
            code: 'LARC6M',
            terms: LIBOR_TERMS,
            min_date: '1997-05-07'.to_date
          },
          :daily_prime => {
            code: 'APRIMEAT',
            terms: LIBOR_TERMS,
            min_date: '2002-08-28'.to_date
          }
        },
        :sbc => {
          :vrc => {
            code: 'SFRC',
            terms: VRC_TERMS,
            min_date:'2002-02-28'.to_date
          },
          :frc => {
            code: 'SFRC',
            terms: FRC_TERMS,
            min_date: '2002-02-28'.to_date
          },
          :'1m_libor' => {
            code: 'SARC1M',
            terms: LIBOR_TERMS,
            min_date: '2002-02-28'.to_date
          },
          :'3m_libor' => {
            code: 'SARC3M',
            terms: LIBOR_TERMS,
            min_date: '2002-02-28'.to_date
          },
          :'6m_libor' => {
            code:'SARC6M',
            terms: LIBOR_TERMS,
            min_date: '2002-02-28'.to_date
          }
        }
      }
    end
  end
end