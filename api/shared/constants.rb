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
      REPORT_PARAM_DATE_FORMAT = /\A\d\d\d\d-(0\d|1[012])-([0-2]\d|3[01])\Z/
      INDEX_CREDIT_TYPES = [:vrc, :frc]
      BASIS_POINT_CREDIT_TYPES = [:'1m_libor', :'3m_libor', :'6m_libor']
      DAILY_PRIME_TRX_IR_CODE_INDEX = 'PRIME'
      DAILY_PRIME_TRX_IR_CODE_BASIS_POINT = 'APRIMEAT'

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