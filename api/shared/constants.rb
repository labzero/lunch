module MAPI
  module Shared
    module Constants
      COLLATERAL_TYPES = [:standard, :sbc]
      CREDIT_TYPES = [:frc, :vrc, :'1m_libor', :'3m_libor', :'6m_libor', :daily_prime, :embedded_cap]
      LOAN_TYPES = [:whole, :agency, :aaa, :aa]
      LOAN_TERMS = [:overnight, :open, :'1week', :'2week', :'3week', :'1month', :'2month', :'3month', :'6month', :'1year', :'2year', :'3year']
      VRC_TERMS = ['1D']
      FRC_TERMS = ['1M', '2M', '3M', '6M', '1Y', '2Y', '3Y', '5Y', '7Y', '10Y', '15Y', '20Y', '30Y']
      LIBOR_TERMS = ['1Y', '2Y', '3Y', '5Y']

      ETRANSACT_TIME_ZONE = 'Pacific Time (US & Canada)'
      REPORT_PARAM_DATE_FORMAT = /\A\d\d\d\d-(0\d|1[012])-([0-2]\d|3[01])\Z/

      IRDB_CODE_TERM_MAPPING =
        {:standard => {
          :vrc => {
            code:'FRADVN',
            terms: VRC_TERMS,
            min_date: '2002-02-28'
          },
          :frc => {
            code: 'FRADVN',
            terms: FRC_TERMS,
            min_date: '1993-02-16'
          },
          :'1m_libor' => {
            code: 'LARC1M',
            terms: LIBOR_TERMS,
            min_date: '1997-05-07'
          },
          :'3m_libor' => {
            code: 'LARC3M',
            terms: LIBOR_TERMS,
            min_date: '1997-05-07'
          },
          :'6m_libor' => {
            code: 'LARC6M',
            terms: LIBOR_TERMS,
            min_date: '1997-05-07'
          },
          :daily_prime => {
            code: 'APRIMEAT',
            terms: LIBOR_TERMS,
            min_date: '2002-08-28'
          }
        },
        :sbc => {
          :vrc => {
            code: 'SFRC',
            terms: VRC_TERMS,
            min_date:'2002-02-28'
          },
          :frc => {
            code: 'SFRC',
            terms: FRC_TERMS,
            min_date: '2002-02-28'
          },
          :'1m_libor' => {
            code: 'SARC1M',
            terms: LIBOR_TERMS,
            min_date: '2002-02-28'
          },
          :'3m_libor' => {
            code: 'SARC3M',
            terms: LIBOR_TERMS,
            min_date: '2002-02-28'
          },
          :'6m_libor' => {
            code:'SARC6M',
            terms: LIBOR_TERMS,
            min_date: '2002-02-28'
          }
        }
      }
    end
  end
end