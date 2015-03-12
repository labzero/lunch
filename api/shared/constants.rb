module MAPI
  module Shared
    module Constants
      LOAN_TYPES = [:whole, :agency, :aaa, :aa]
      LOAN_TERMS = [:overnight, :open, :'1week', :'2week', :'3week', :'1month', :'2month', :'3month', :'6month', :'1year', :'2year', :'3year']

      ETRANSACT_TIME_ZONE = 'Pacific Time (US & Canada)'
      REPORT_PARAM_DATE_FORMAT = /\A\d\d\d\d-(0\d|1[012])-([0-2]\d|3[01])\Z/
    end
  end
end